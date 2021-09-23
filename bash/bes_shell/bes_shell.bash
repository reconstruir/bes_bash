#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

function _bes_shell_this_dir()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  return 0
}

_BES_SHELL_THIS_DIR="$(_bes_shell_this_dir)"

function _bes_trace() ( if [[ "$_BES_TRACE" == "1" ]]; then printf '_BES_TRACE: %s\n' "$*"; fi )
function _bes_trace_function() ( _bes_trace "func: ${FUNCNAME[1]}($*)" )
function _bes_trace_file() ( _bes_trace "file: ${BASH_SOURCE}: $*" )

function bes_import()
{
  _bes_trace_function $*

  if [[ $# != 1 ]]; then
    echo "usage: bes_import filename"
    return 1
  fi

  local _filename="${1}"
  local _this_dir="$(_bes_shell_this_dir)"
  local _filename_abs="${_this_dir}/${_filename}"
  if [[ ! -f "${_filename_abs}" ]]; then
    local _basename="$(basename ${_filename_abs})"
    echo "bes_import: ${BASH_SOURCE[1]}:${BASH_LINENO[0]}: file \"${_basename}\"not found in ${_this_dir}"
    exit 1
  fi

  local _sanitized_filename=$(echo ${_filename} | tr '[:punct:]' '_' | tr '[:space:]' '_')
  local _var_name=__imported_${_sanitized_filename}__
  local _var_value=$(eval 'printf "%s\n" "${'"${_var_name}"'}"')
  if [[ "${_var_value}" == "true" ]]; then
    return 0
  fi
  source "${_filename_abs}"
  eval "${_var_name}=\"true\""
  return 0
}

# Source a shell file or print an error if it does not exist
function bes_source_file()
{
  _bes_trace_function $*
  if [[ $# < 1 ]]; then
    echo "Usage: bes_source_file filename"
    return 1
  fi
  local _filename="${1}"
  if [[ ! -e "${_filename}" ]]; then
    echo "bes_source_file: File not found: ${_filename}"
    return 1
  fi
  if [[ ! -f "${_filename}" ]]; then
    echo "bes_source_file: Not a file: ${_filename}"
    return 1
  fi
  source "${_filename}"
  return 0
}

# Source a shell file but only if it exists
function bes_source_file_if()
{
  _bes_trace_function $*
  if [[ $# < 1 ]]; then
    printf "\nUsage: bes_source filename\n\n"
    return 1
  fi
  local _filename="${1}"
  if [[ ! -f "${_filename}" ]]; then
    return 1
  fi
  bes_source_file "${_filename}"
  return $?
}

# Return an exit code of 0 if the argument is "true."  true is one of: true, 1, t, yes, y
function bes_is_true()
{
  if [[ $# < 1 ]]; then
    printf "\nUsage: bes_is_true what\n\n"
    return 1
  fi
  local _what=$( echo "$1" | $_BES_TR_EXE '[:upper:]' '[:lower:]' )
  local _rv
  case "${_what}" in
    true|1|t|y|yes)
      _rv=0
      ;;
    *)
      _rv=1
      ;;
  esac
  return ${_rv}
}

function bes_script_name()
{
  if [[ -n "${_BES_SCRIPT_NAME}"  ]]; then
    echo "${_BES_SCRIPT_NAME}"
    return 0
  fi
  if [[ ${0} =~ .+bash$ ]]; then
    echo "bes_shell"
    return 0
  fi
  echo $(basename "${0}")
  return 0
}

function bes_message()
{
  local _script_name=$(bes_script_name)
  echo ${_script_name}: ${1+"$@"}
  return 0
}

function bes_debug_message()
{
  if [[ -z "${BES_DEBUG}" ]]; then
    return 0
  fi
  local _output=""
  if [[ -n "${BES_LOG_FILE}" ]]; then
    _output="${BES_LOG_FILE}"
  else
    if [[ -t 1 ]]; then
      _output=$(tty)
    fi
  fi
  local _script_name=$(bes_script_name)
  local _pid=$$
  local _message=$(printf "%s(%s): %s\n" ${_script_name} ${_pid} ${1+"$@"})
  if [[ -n "${_output}" ]]; then
    echo ${_message} >> ${_output}
  else
    echo ${_message}
  fi
  return 0
}

function bes_console_message()
{
  if bes_is_ci ; then
    BES_DEBUG=1 bes_debug_message ${1+"$@"}
  else    
    BES_DEBUG=1 BES_LOG_FILE=$(tty) bes_debug_message ${1+"$@"}
  fi
  return $?
}

function bes_function_exists()
{
  local _name=${1}
  local _type=$(type -t ${_name})
  if [[ "${_type}" == "function" ]]; then
    return 0
  else
    return 1
  fi
}

function _bes_function_invoke()
{
  _bes_trace_function $*
  if [[ $# < 2 ]]; then
    printf "\nUsage: _bes_function_invoke function default_rv args\n\n"
    return 1
  fi
  local _function=${1}
  shift
  local _default_rv=${1}
  shift
  local _rv=${_default_rv}
  if bes_function_exists ${_function}; then
    eval ${_function} ${1+"$@"}
    _rv=$?
  fi
  return ${_rv}
}

# invoke a function if it exists.  returns exit code of function or 1 if the function does not exist.
function bes_function_invoke()
{
  _bes_trace_function $*
  if [[ $# < 1 ]]; then
    printf "\nUsage: bes_function_invoke_if function args\n\n"
    return 1
  fi
  local _function=${1}
  shift
  _bes_function_invoke ${_function} 1 ${1+"$@"}
  local _rv=$?
  return ${_rv}
}

# invoke a function if it exists.  returns exit code of function or 0 if the function does not exist.
function bes_function_invoke_if()
{
  _bes_trace_function $*
  if [[ $# < 1 ]]; then
    printf "\nUsage: bes_function_invoke_if function args\n\n"
    return 1
  fi
  local _function=${1}
  shift
  _bes_function_invoke ${_function} 0 ${1+"$@"}
  local _rv=$?
  return ${_rv}
}

# atexit function suitable for trapping and printing the exit code
# trap "bes_atexit_message_successful ${_remote_name}" EXIT
function bes_atexit_message_successful()
{
  local _actual_exit_code=$?
  if [[ ${_actual_exit_code} == 0 ]]; then
    bes_message success ${1+"$@"}
  else
    bes_message failed ${1+"$@"}
  fi
  return ${_actual_exit_code}
}

function bes_atexit_remove_dir_handler()
{
  local _actual_exit_code=$?
  if [[ $# != 1 ]]; then
    bes_message "Usage: _bes_atexit_remove_dir_handler dir"
    return 1
  fi
  local _dir="${1}"
  if [[ -e "${_dir}" ]]; then
    if [[ ! -d "${_dir}" ]]; then
      bes_message "_bes_atexit_remove_dir_handler: not a directory: ${_dir}"
      return 1
    fi
    bes_debug_message "_bes_atexit_remove_dir_handler: removing ${_dir}"
    /bin/rm -rf ${_dir}
  else
    bes_debug_message "_bes_atexit_remove_dir_handler: directory not found ${_dir}"
  fi
  return ${_actual_exit_code}
}
