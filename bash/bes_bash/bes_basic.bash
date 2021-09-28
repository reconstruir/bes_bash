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

  if _bes_import_filename_is_imported "${_filename_abs}"; then
    return 0
  fi
  
  if [[ ! -f "${_filename_abs}" ]]; then
    local _basename="$(basename ${_filename_abs})"
    echo "bes_import: ${BASH_SOURCE[1]}:${BASH_LINENO[0]}: file \"${_basename}\" not found in ${_this_dir}"
    exit 1
  fi

  source "${_filename_abs}"
  _bes_import_filename_set_imported "${_filename_abs}"
  return 0
}

function _bes_import_filename_variable_name()
{
  if [[ $# != 1 ]]; then
    echo "usage: _bes_import_filename_variable_name filename"
    return 1
  fi

  local _filename="${1}"
  local _basename="$(basename "${_filename}")"
  local _sanitized_basename=$(echo ${_basename} | tr '[:punct:]' '_' | tr '[:space:]' '_')
  local _var_name=__imported_${_sanitized_basename}__
  echo ${_var_name}
  return 0
}

function _bes_import_filename_set_imported()
{
  if [[ $# != 1 ]]; then
    echo "usage: _bes_import_filename_mark_imported filename"
    return 1
  fi
  local _filename="${1}"
  local _var_name=$(_bes_import_filename_variable_name "${_filename}")
  eval "${_var_name}=\"true\""
  return 0
}

function _bes_import_filename_is_imported()
{
  if [[ $# != 1 ]]; then
    echo "usage: _bes_import_filename_is_imported filename"
    return 1
  fi
  local _filename="${1}"
  local _var_name=$(_bes_import_filename_variable_name "${_filename}")
  local _var_value=$(eval 'printf "%s\n" "${'"${_var_name}"'}"')
  if [[ "${_var_value}" == "true" ]]; then
    return 0
  fi
  return 1
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

# Get a var value
function bes_var_get()
{
  eval 'printf "%s\n" "${'"$1"'}"'
}

# Set a var value
function bes_var_set()
{
  eval "$1=\"\$2\""
}

# Unset a var value
function bes_var_unset()
{
  eval "unset $1"
}

# Export a var value
function bes_var_export()
{
  eval "export $1=\"\$2\""
}

_BES_LOG_FILE=$(tty)

function bes_log()
{
  if [[ $# < 3 ]]; then
    echo "Usage: bes_log component level <message>"
    return 1
  fi
  local _component=${1}
  shift
  local _level=${1}
  shift
  if ! bes_log_level_matches ${_component} ${_level}; then
    return 0
  fi
  local _timestamp=$(date +"%Y_%m_%d-%H:%M:%S-%Z")
  local _pid="$$"
  local _label="${_component}.${_level}"
  local _text=$(printf "${_timestamp} [${_pid}] (${_label}) %s\n" "$*")
  if [[ -z "${_BES_LOG_FILE}" ]]; then
    echo "${_text}"
  else
    echo "${_text}" > ${_BES_LOG_FILE}
  fi
  return 0
}

function bes_log_level_set()
{
  if [[ $# != 2 ]]; then
    echo "Usage: bes_log_level_set component error|warning|info|debug|trace"
    return 1
  fi
  local _component=${1}
  local _level=${2}
  _bes_log_level_check bes_log_level_set ${_level}
  local _var_name="_BES_LOG_CONFIG_${_component}"
  bes_var_set ${_var_name} ${_level}
}

function bes_log_level_get()
{
  if [[ $# != 1 ]]; then
    echo "Usage: bes_log_level_get component"
    return 1
  fi
  local _component=${1}
  local _var_name="_BES_LOG_CONFIG_${_component}"
  local _level="$(bes_var_get ${_var_name})"
  if [[ -z "${_level}" ]]; then
    _level=error
  fi
  echo ${_level}
  return 0
}

function bes_log_level_matches()
{
  if [[ $# != 2 ]]; then
    echo "Usage: bes_log_level_matches component error|warning|info|debug|trace"
    return 1
  fi
  local _component=${1}
  local _level=${2}
  _bes_log_level_check bes_log_level_matches ${_level}
  local _current_level=$(bes_log_level_get ${_component})
  case "${_current_level}" in
    error)
      case "${_level}" in
        error)
          return 0
          ;;
        *)
          return 1
          ;;
      esac
      ;;
    warning)
      case "${_level}" in
        error|warning)
          return 0
          ;;
        *)
          return 1
          ;;
      esac
      ;;
    info)
      case "${_level}" in
        error|warning|info)
          return 0
          ;;
        *)
          return 1
          ;;
      esac
      ;;
    debug)
      case "${_level}" in
        error|warning|info|debug)
          return 0
          ;;
        *)
          return 1
          ;;
      esac
      ;;
    trace)
      return 0
      ;;
  esac
  return 1
}

function bes_log_config()
{
  local _items=(${@})
  local _item
  for _item in "${_items[@]}"; do
    local _component=$(echo ${_item} | awk -F"=" '{ print $1; }')
    local _level=$(echo ${_item} | awk -F"=" '{ print $2; }')
    if [[ -z "${_level}" ]]; then
      _level=error
    fi
    bes_log_level_set ${_component} ${_level}
  done
}

function _bes_log_level_is_valid()
{
  if [[ $# != 1 ]]; then
    echo "Usage: _bes_log_level_is_valid level"
    return 1
  fi
  local _level=${1}
  case "${_level}" in
    error|warning|info|debug|trace)
      return 0
      ;;
    *)
      ;;
  esac
  return 1
}

function _bes_log_level_check()
{
  if [[ $# != 2 ]]; then
    echo "Usage: _bes_log_level_is_valid label level"
    return 1
  fi
  local _label=${1}
  local _level=${2}
  if ! _bes_log_level_is_valid ${_level}; then
    echo "$_label: Invalid log level: ${_level}.  Should be one of error|warning|info|debug|trace"
    exit 1
  fi
  return 0
}

if [[ -n ${BES_LOG} ]]; then
  bes_log_config "${BES_LOG}"
fi

function bes_log_trace_function()
{
  if [[ $# < 1 ]]; then
    echo "Usage: bes_log_trace_function component"
    return 1
  fi
  local _component=${1}
  shift
  bes_log ${_component} trace "${FUNCNAME[1]}($*)"
}

function bes_log_trace_file()
{
  if [[ $# < 1 ]]; then
    echo "Usage: bes_log_trace_function component"
    return 1
  fi
  local _component=${1}
  shift
  bes_log ${_component} trace "${BASH_SOURCE}: ($*)"
}

function bes_log_set_log_file()
{
  if [[ $# != 1 ]]; then
    echo "Usage: bes_log_set_log_file log_file"
    return 1
  fi
  local _log_file="${1}"
  _BES_LOG_FILE="${_log_file}"
  return 0
}
