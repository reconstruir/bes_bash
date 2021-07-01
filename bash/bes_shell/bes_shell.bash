#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

function _bes_shell_this_dir()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  return 0
}

_BES_SHELL_THIS_DIR="$(_bes_shell_this_dir)"

source "${_BES_SHELL_THIS_DIR}/bes_var.bash"
source "${_BES_SHELL_THIS_DIR}/bes_log.bash"
source "${_BES_SHELL_THIS_DIR}/bes_system.bash"
source "${_BES_SHELL_THIS_DIR}/bes_list.bash"
source "${_BES_SHELL_THIS_DIR}/bes_path.bash"

_bes_trace_file "begin"

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

# deprecated
function bes_source()
{
  _bes_trace_function $*
  bes_source_file $@
  return $?
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

# Convert a single argument string to lower case
function bes_to_lower()
{
  local _result=$( echo "$@" | $_BES_TR_EXE '[:upper:]' '[:lower:]' )
  echo ${_result}
  return 0
}

# Return an exit code of 0 if the argument is "true."  true is one of: true, 1, t, yes, y
function bes_is_true()
{
  if [[ $# < 1 ]]; then
    printf "\nUsage: bes_is_true what\n\n"
    return 1
  fi
  local _what=$(bes_to_lower "$1")
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

function bes_setup()
{
  _bes_trace_function $*
  if [[ $# < 1 ]]; then
    printf "\nUsage: bes_setup root_dir [go_there]\n\n"
    return 1
  fi
  local _root_dir=$1
  local _go_there=true
  if [[ $# > 1 ]]; then
    _go_there=$2
  fi

  bes_env_path_prepend PATH ${_root_dir}/bin
  bes_env_path_prepend PYTHONPATH ${_root_dir}/lib

  if $(bes_is_true $_go_there); then
    cd $_root_dir
    bes_tab_title $($_BES_BASENAME_EXE $_root_dir)
  fi
  
  return 0
}

function bes_unsetup()
{
  _bes_trace_function $*
  if [[ $# < 1 ]]; then
    printf "\nUsage: bes_unsetup root_dir\n\n"
    return 1
  fi
  local _root_dir=$1
  bes_env_path_remove PATH ${_root_dir}/bin
  bes_env_path_remove PYTHONPATH ${_root_dir}/lib
  bes_tab_title ""
  return 0
}

function bes_setup_v2()
{
  function _bes_setup_v2_help()
  {
    cat << EOF
Usage: bes_setup_v2 <options> root_dir

  Where options is one or more of:

    -h,--help     Show this help.
    -o,--ouput    Output the resulting egoist path to the given filename. []
    -p,--purpose  The purpose of the egosit [ general ]

EOF
  }

  _bes_trace_function $*

  local _root_dir
  local _set_title=false
  local _change_dir=false
  local _set_path=false
  local _set_pythonpath=false
  local _venv_config=false
  local _positional_args=()
  local _key
  while [[ $# -gt 0 ]]; do
    _key="${1}"
    bes_debug_message "bes_setup_v2: checking key ${_key} ${2}"
    case ${_key} in
      --venv-config)
        _venv_config="${2}"
        shift # past argument
        shift # past value
        ;;
      --venv-activate)
        _venv_activate=true
        shift # past argument
        ;;
      --no-venv-activate|-nva)
        _venv_activate=false
        shift # past argument
        ;;
      --set-path)
        _set_path=true
        shift # past argument
        ;;
      --set-python-path)
        _set_python_path=true
        shift # past argument
        ;;
      --change-dir)
        _change_dir=true
        shift # past argument
        ;;
      --no-change-dir|-ncd)
        _change_dir=false
        shift # past argument
        ;;
      --set-title)
        _set_title=true
        shift # past argument
        ;;
      --help|-h)
        _bes_setup_v2_help
        shift # past argument
        return 0
        ;;
      *)    # unknown option
        positional_args+=("${1}") # save it in an array for later
        shift # past argument
        ;;
    esac
  done
  
  set -- "${positional_args[@]}" # restore positional parameters

  local _root_dir="${1}"
  if [[ $# -ge 1 ]]; then
    _root_dir="${1}"
    shift
  fi

  if [[ ! $# -eq 0 ]]; then
    printf "\nbes_setup_v2: unknown arguments: $*\n\n"
    return 1
  fi
  if [[ ${_set_path} == true ]]; then
    bes_env_path_prepend PATH "${_root_dir}/bin"
  fi
  if [[ ${_set_python_path} == true ]]; then
    bes_env_path_prepend PYTHONPATH "${_root_dir}/lib"
  fi
  if [[ ${_change_dir} == true ]]; then
    cd "${_root_dir}"
  fi
  if [[ ${_set_title} == true ]]; then
    bes_tab_title $($_BES_BASENAME_EXE "${_root_dir}")
  fi
  if [[ -n "${_venv_config}" ]]; then
    if [[ ! -f "${_venv_config}" ]]; then
      printf "\nbes_setup_v2: venv activate config not found: ${_venv_config}\n\n"
      return 1
    fi
    if [[ ${_venv_activate} == true ]]; then
      source "${_venv_config}"
    fi
  fi
  return 0
}

function bes_PATH()
{
  bes_env_path_print PATH
}

function bes_PYTHONPATH()
{
  bes_env_path_print PYTHONPATH
}

function bes_LD_LIBRARY_PATH()
{
  bes_env_path_print LD_LIBRARY_PATH
}

function bes_tab_title()
{
  echo -ne "\033]0;"$*"\007"
  local _prompt=$(echo -ne "\033]0;"$*"\007")
  export PROMPT_COMMAND='${_prompt}'
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

function bes_is_ci()
{
  if [[ -n "${CI}"|| -n "${HUDSON_COOKIE}" ]]; then
    return 0
  fi
  return 1
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

# FIXME: retire this one
function bes_invoke()
{
  bes_function_invoke_if ${1+"$@"}
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

# DEPRECATED: use bes_abs_dir instead
# Return the absolute path for the path arg
function bes_abs_path()
{
  if [[ $# < 1 ]]; then
    bes_message "usage: bes_abs_path path"
    return 1
  fi
  local _path="${1}"
  echo $(cd ${_path} && pwd)
  return 0
}

# Return the absolute dir path for path.  Note that path will be created
# if it doesnt exist so that this function can be used for paths that
# dont yet exist.  That is useful for scripts that want to normalize
# their file input/output arguments.
function bes_abs_dir()
{
  if [[ $# < 1 ]]; then
    bes_message "usage: bes_abs_dir path"
    return 1
  fi
  local _path="${1}"
  if [[ ! -d "${_path}" ]]; then
    $_BES_MKDIR_EXE -p "${_path}"
  fi
  local _result="$(cd "${_path}" && $_BES_PWD_EXE)"
  echo ${_result}
  return 0
}

function bes_abs_file()
{
  if [[ $# < 1 ]]; then
    bes_message "usage: bes_abs_file filename"
    return 1
  fi
  local _filename="${1}"
  local _dirname="$($_BES_DIRNAME_EXE "${_filename}")"
  local _basename="$($_BES_BASENAME_EXE "${_filename}")"
  local _abs_dirname="$(bes_abs_dir "${_dirname}")"
  local _result="${_abs_dirname}"/"${_basename}"
  echo ${_result}
  return 0
}

function bes_str_split()
{
  if [[ $# < 2 ]]; then
    bes_message "usage: bes_str_split string delimiter"
    return 1
  fi
  local _string="${1}"
  local _delimiter="${2}"
  local _saveIFS="${IFS}"
  local _result
  IFS="${_delimiter}" read -r -a _result <<< "${_string}"
  echo "${_result[@]}"
  IFS="${_saveIFS}"
  return 0
}

# return just the extension of a file
function bes_file_extension()
{
  if [[ $# < 1 ]]; then
    bes_message "usage: bes_file_extension filename"
    return 1
  fi
  local _filename="${1}"
  local _base=$($_BES_BASENAME_EXE -- "${_filename}")
  local _ext="${_base##*.}"
  echo "${_ext}"
  return 0
}

# print the file size in bytes
function bes_file_size()
{
  if [[ $# < 1 ]]; then
    bes_message "usage: bes_file_size filename"
    return 1
  fi
  local _filename="${1}"
  local _file_size=$(wc -c < "${_filename}" | tr -d ' ')
  echo "${_file_size}"
  return 0
}

# return 0 if str is an integer
function bes_str_is_integer()
{
  if [[ $# < 1 ]]; then
    bes_message "usage: bes_str_is_integer str"
    return 1
  fi
  local _str="${1}"
  local _pattern='^[0-9]+$'
  if [[ ${_str} =~ ${_pattern} ]]; then
    return 0
  fi
  return 1
}

# return 0 if str starts with head
function bes_str_starts_with()
{
  if [[ $# != 2 ]]; then
    bes_message "usage: bes_str_starts_with str head"
    return 1
  fi
  local _str="${1}"
  local _head="${2}"
  local _pattern="^${_head}.*$"
  if [[ "${_str}" =~ ${_pattern} ]]; then
    return 0
  fi
  return 1
}

# return 0 if str ends with tail
function bes_str_ends_with()
{
  if [[ $# != 2 ]]; then
    bes_message "usage: bes_str_ends_with str tail"
    return 1
  fi
  local _str="${1}"
  local _tail="${2}"
  local _pattern="^.*${_tail}$"
  if [[ "${_str}" =~ ${_pattern} ]]; then
    return 0
  fi
  return 1
}

# Remove head from str
function bes_str_remove_head()
{
  if [[ $# != 2 ]]; then
    bes_message "usage: bes_str_remove_head str head"
    return 1
  fi
  local _str="${1}"
  local _head="${2}"
  echo ${_str#${_head}}
  return 0
}

# Remove tail from str
function bes_str_remove_tail()
{
  if [[ $# != 2 ]]; then
    bes_message "usage: bes_str_remove_tail str tail"
    return 1
  fi
  local _str="${1}"
  local _tail="${2}"
  echo ${_str%${_tail}}
  return 0
}

function bes_question_yes_no()
{
  if [[ $# != 2 ]]; then
    echo "usage: bes_question_yes_no var_name message"
    return 1
  fi
  local _CHOICES="[y]es [n]o"
  local _var_name="${1}"
  local _message="${2}"
  local _local_answer
  local _result=1
  while true; do
    read -p "${_message} - ${_CHOICES}: " _local_answer
    case "${_local_answer}" in
      y|Y|yes|YES)
        _result=yes
        break
        ;;
      n|N|no|NO)
        _result=no
        break
        ;;
      *)
        bes_message "Invalid answer: ${_local_answer}.  Please answer: ${_CHOICES}"
    esac
  done
  eval ${_var_name}=${_result}
  return 0
}

function bes_file_check()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_file_check label"
    return 1
  fi
  local _label=${FUNCNAME[1]}
  local _filename="${1}"
  if [[ ! -e "${_filename}" ]]; then
    bes_message "${_label}: not found: ${_filename}"
    exit 1
  fi
  return 0
}

_bes_trace_file "end"