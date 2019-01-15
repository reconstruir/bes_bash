#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

function _bes_trace() ( if [[ "$_BES_TRACE" == "1" ]]; then printf '_BES_TRACE: %s\n' "$*"; fi )
function _bes_trace_function() ( _bes_trace "func: ${FUNCNAME[1]}($*)" )
function _bes_trace_file() ( _bes_trace "file: ${BASH_SOURCE}: $*" )

_bes_trace_file "begin"

_BES_BASIC_PATH=$(PATH=/bin:/usr/bin env -i bash -c "echo \"${PATH}\"")

_BES_AWK_EXE=$(PATH=${_BES_BASIC_PATH} which awk)
_BES_TR_EXE=$(PATH=${_BES_BASIC_PATH} which tr)
_BES_BASENAME_EXE=$(PATH=${_BES_BASIC_PATH} which basename)

# return a colon separated path without the head item
function bes_path_without_head()
{
  local _path="$*"
  local _head=${_path%%:*}
  local _without_head=${_path#*:}
  if [[ "${_without_head}" == "${_head}" ]]; then
    _without_head=""
  fi
  echo ${_without_head}
  return 0
}

# return just the head item of a colon separated path
function bes_path_head()
{
  local _path="$*"
  local _head=${_path%%:*}
  echo ${_head}
  return 0
}

# Strip rogue colon(s) from head of path
function bes_path_head_strip_colon()
{
  local _path="$*"
  local _result="${_path#:}"
  while [[ "${_result}" != "${_path}" ]]; do
    _path="${_result}"
    _result="${_path#:}"
  done
  echo "${_result}"
  return 0
}

# Strip rogue colon(s) from tail of path
function bes_path_tail_strip_colon()
{
  local _path="$*"
  local _result="${_path%:}"
  while [[ "${_result}" != "${_path}" ]]; do
    _path="${_result}"
    _result="${_path%:}"
  done
  echo "${_result}"
  return 0
}

# Strip rogue colon(s) from head and tail of path
function bes_path_strip_colon()
{
  local _path="$*"
  local _result=$(bes_path_head_strip_colon "${_path}")
  echo $(bes_path_tail_strip_colon "${_result}")
  return 0
}

# remove duplicates from a path
# from https://unix.stackexchange.com/questions/14895/duplicate-entries-in-path-a-problem
function bes_path_dedup()
{
  _bes_trace_function $*
  if [[ $# != 1 ]]; then
    echo "Usage: bes_path_dedup path"
    return 1
  fi
  local _tmp="$*"
  local _head
  local _result=""
  while [[ -n "$_tmp" ]]; do
    _head=$(bes_path_head "${_tmp}")
    _tmp=$(bes_path_without_head "${_tmp}")
    case ":${_result}:" in
      *":${_head}:"*) :;; # already there
      *) _result="${_result}:${_head}";;
    esac
  done
  echo $(bes_path_strip_colon "${_result}")
  return 0
}

# sanitize a path by deduping entries and stripping leading or trailing colons
function bes_path_sanitize()
{
  if [[ $# -ne 1 ]]; then
    echo "Usage: bes_path_sanitize path"
    return 1
  fi
  local _path=$(bes_path_dedup "$1")
  echo $(bes_path_strip_colon "${_path}")
  return 0
}

function bes_path_remove()
{
  _bes_trace_function $*
  if [[ $# < 2 ]]; then
    echo "Usage: bes_path_remove path p1 p2 ... pN"
    return 1
  fi
  local _tmp="$1"
  shift
  local _head
  local _result=""
  while [[ -n "$_tmp" ]]; do
    _head=$(bes_path_head "${_tmp}")
    _tmp=$(bes_path_without_head "${_tmp}")
    if ! bes_is_in_list "$_head" "$@"; then
      if [[ -z ${_result} ]]; then
        _result="${_head}"
      else
        _result="${_result}:${_head}"
      fi
    fi
  done
  echo "${_result}"
  return 0
}

function bes_path_append()
{
  _bes_trace_function $*
  if [[ $# < 2 ]]; then
    echo "Usage: bes_path_append path p1 p2 ... pN"
    return 1
  fi
  local path="$1"
  shift
  local what
  local result="${path}"
  while [[ $# > 0 ]]; do
    what="$1"
    result=$(bes_path_remove "${result}" "${what}")
    result="${result}":"${what}"
    shift
  done
  result=$(bes_path_sanitize "${result}")
  echo "${result}"
  return 0
}

function bes_path_prepend()
{
  _bes_trace_function $*
  if [[ $# < 2 ]]; then
    echo "Usage: bes_path_prepend path p1 p2 ... pN"
    return 1
  fi
  local _path="$1"
  shift
  local _what
  local _result="${_path}"
  while [[ $# > 0 ]]; do
    _what="$1"
    _result="${_what}":"${_result}"
    shift
  done
  echo $(bes_path_sanitize "${_result}")
  return 0
}

function bes_path_print()
{
  if [[ $# != 1 ]]; then
    echo "Usage: bes_path_print path"
    return 1
  fi
  local _tmp="$*"
  local _head
  while [[ -n "$_tmp" ]]; do
    _head=$(bes_path_head "${_tmp}")
    _tmp=$(bes_path_without_head "${_tmp}")
    echo ${_head/$HOME/\~}
  done
  return 0
}

function bes_env_path_sanitize()
{
  _bes_trace_function $*
  local _var_name=$(bes_variable_map $1)
  local _value=$(bes_var_get $_var_name)
  local _new_value=$(bes_path_sanitize "$_value")
  bes_var_set $_var_name "$_new_value"
  return 0
}

function bes_env_path_append()
{
  _bes_trace_function $*
  local _var_name=$(bes_variable_map $1)
  shift
  local _parts="$@"
  local _value=$(bes_var_get $_var_name)
  local _new_value=$(bes_path_append "$_value" "$_parts")
  bes_var_set $_var_name "$_new_value"
  export $_var_name
  return 0
}

function bes_env_path_prepend()
{
  _bes_trace_function $*
  local _var_name=$(bes_variable_map $1)
  shift
  local _parts="$@"
  local _value=$(bes_var_get $_var_name)
  local _new_value=$(bes_path_prepend "$_value" "$_parts")
  bes_var_set $_var_name "$_new_value"
  export $_var_name
  return 0
}

function bes_env_path_remove()
{
  _bes_trace_function $*
  local _var_name=$(bes_variable_map $1)
  shift
  local _parts="$@"
  local _value=$(bes_var_get $_var_name)
  local _new_value=$(bes_path_remove "$_value" "$_parts")
  bes_var_set $_var_name "$_new_value"
  export $_var_name
  return 0
}

function bes_env_path_clear()
{
  _bes_trace_function $*
  local _var_name=$(bes_variable_map $1)
  bes_var_set $_var_name ""
  export $_var_name
  return 0
}

function bes_env_path_print()
{
  _bes_trace_function $*
  local _var_name=$(bes_variable_map $1)
  local _value=$(bes_var_get $_var_name)
  bes_path_print $_value
  return 0
}

# Return system host name.  linux or macos same as bes_shell/system/host.py
function bes_system()
{
  _bes_trace_function $*
  local _uname_exe=$(PATH=${_BES_BASIC_PATH} which uname)
  local _uname=$(${_uname_exe})
  local _result
  case "${_uname}" in
    Linux)
      _result="linux"
      ;;
    Darwin)
      _result="macos"
      ;;
    *)
      _result="unknown"
      ;;
  esac
  echo "${_result}"
  return 0
}

# Source a shell file if it exists
function bes_source()
{
  _bes_trace_function $*
  if [[ $# < 1 ]]; then
    printf "\nUsage: bes_source filename\n\n"
    return 1
  fi
  local _filename=$1
  if [[ -f $_filename ]]; then
     source $_filename
     return 0
  fi
  return 1
}

function bes_invoke()
{
  _bes_trace_function $*
  if [[ $# < 1 ]]; then
    printf "\nUsage: bes_invoke function\n\n"
    return 1
  fi
  local _function=$1
  local _rv=1
  if type $_function >& /dev/null; then
    eval $_function
    _rv=$?
  fi
  return $_rv
}

# Source all the *.sh files in a dir if it exists and has such files
function bes_source_dir()
{
  _bes_trace_function $*
  if [[ $# < 1 ]]; then
    printf "\nUsage: bes_source_dir dir\n\n"
    return 1
  fi
  local _dir=$1
  if [[ ! -d $_dir ]]; then
    return 0
  fi
  local _files=$(find $_dir -maxdepth 1 -name "*.sh")
  local _file
  for _file in $_files; do
    source "$_file"
  done
  return 0
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

# Return 0 if the first argument is in any of the following arguments
function bes_is_in_list()
{
  if [[ $# < 1 ]]; then
    printf "\nUsage: bes_is_in_list what l1 l2 ... lN\n\n"
    return 1
  fi
  local _what="$1"
  shift
  local _next
  while [[ $# > 0 ]]; do
    _next="$1"
    if [[ "$_what" == "$_next" ]]; then
      return 0
    fi
    shift
  done
  return 1
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

function _bes_variable_map_macos()
{
  local _var_name=$1
  local _rv
  case ${_var_name} in
    LD_LIBRARY_PATH)
      _rv=DYLD_LIBRARY_PATH
      ;;
    *)
      _rv=${_var_name}
      ;;
  esac
  echo ${_rv}
  return 0
}

function _bes_variable_map_linux()
{
  local _var_name=$1
  local _rv
  case ${_var_name} in
    DYLD_LIBRARY_PATH)
      _rv=LD_LIBRARY_PATH
      ;;
    *)
      _rv=${_var_name}
      ;;
  esac
  echo ${_rv}
  return 0
}

function bes_variable_map()
{
  if [[ $# < 1 ]]; then
    echo "Usage: bes_variable_map var_name"
    return 1
  fi
  local _system=$(bes_system)
  local _var_name=$1
  local _rv
  case ${_system} in
    macos)
      _rv=$(_bes_variable_map_macos ${_var_name})
      ;;
    linux|*)
      _rv=$(_bes_variable_map_linux ${_var_name})
      ;;
  esac
  echo ${_rv}
  return 0
}

function LD_LIBRARY_PATH_var_name()
{
  local _system=$(bes_system)
  local _rv=
  case ${_system} in
    macos)
      _rv=DYLD_LIBRARY_PATH
      ;;
    linux|*)
      _rv=LD_LIBRARY_PATH
      ;;
  esac
  echo $_rv
  return 0
}

function bes_tab_title()
{
  echo -ne "\033]0;"$*"\007"
  local _prompt=$(echo -ne "\033]0;"$*"\007")
  export PROMPT_COMMAND='${_prompt}'
}

# Mostly borrowed from https://unwiredcouch.com/2016/04/13/bash-unit-testing-101.html

# Print all the unit tests defined in this script environment (functions starting with test_)
function bes_testing_print_unit_tests()
{
  local _result
  declare -a _result
  i=$(( 0 ))
  for unit_test in $(declare -f | grep -o "^test_[a-zA-Z_0-9]*"); do
    _result[$i]=$unit_test
    i=$(( $i + 1 ))
  done
  echo ${_result[*]}
  return 0
}

_bes_testing_exit_code=0

# Run all the unit tests found in this script environment
function bes_testing_run_unit_tests()
{
  local _tests=$(bes_testing_print_unit_tests)
  local _test
  local _rv
  for _test in $_tests; do
    ${_test}
  done
  exit $_bes_testing_exit_code
}

# Run that an expression argument is true and print that
function bes_assert()
{
  local _filename=$($_BES_BASENAME_EXE ${BASH_SOURCE[1]})
  local _line=${BASH_LINENO[0]}
  local _function=${FUNCNAME[1]}
  
  eval "${1}"
  if [[ $? -ne 0 ]]; then
    echo "failed: " ${1} " at $_filename:$_line"
    _bes_testing_exit_code=1
  else
    echo "$_filename $_function: passed"
  fi
}

function bes_system_info()
{
  local _uname_exe=$(PATH=${_BES_BASIC_PATH} which uname)
  local _uname=$(${_uname_exe})
  local _system='unknown'
  local _arch=$(${_uname_exe} -m)
  local _distro=
  local _major=
  local _minor=
  local _path=
  local _version=
  case ${_uname} in
    Darwin)
      _system='macos'
      _version=$(/usr/bin/defaults read loginwindow SystemVersionStampAsString | ${_BES_AWK_EXE} -F"." '{ printf("%s.%s\n", $1, $2); }')
      _major=$(echo {_version} | ${_BES_AWK_EXE} -F"." '{ print $1; }')
      _minor=$(echo {_version} | ${_BES_AWK_EXE} -F"." '{ print $2; }')
      _path=${_system}-${_major}/${_arch}
      ;;
	  Linux)
      _system='linux'
      _version=$(cat /etc/os-release | grep VERSION_ID= | ${_BES_AWK_EXE} -F"=" '{ print $2; }' | ${_BES_AWK_EXE}  -F"." '{ printf("%s.%s\n", $1, $2); }')
      _major=$(echo ${_version} | ${_BES_AWK_EXE} -F"." '{ print $1; }')
      _minor=$(echo ${_version} | ${_BES_AWK_EXE} -F"." '{ print $2; }')
      _distro=$(cat /etc/os-release | grep -e '^ID=' | ${_BES_AWK_EXE} -F"=" '{ print $2; }')
      _path=${_system}-${_distro}-${_major}/${_arch}
      ;;
	esac
  echo ${_system}:${_distro}:${_major}:${_minor}:${_arch}:${_path}
  return 0
}

function bes_system()
{
  local _path=$(bes_system_info | ${_BES_AWK_EXE} -F":" '{ print $1 }')
  echo ${_path}
  return 0
}

function bes_system_path()
{
  local _path=$(bes_system_info | ${_BES_AWK_EXE} -F":" '{ print $6 }')
  echo ${_path}
  return 0
}

_bes_trace_file "end"
