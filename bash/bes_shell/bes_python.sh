#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

# Functions to deal with python

_bes_trace_file "begin"

# Return 0 if the python version given is found
function bes_has_python()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_has_python version"
    return 1
  fi
  local _version=${1}
  local _python_exe=python${_version}
  if bes_has_program ${_python_exe}; then
    return 0
  fi
  return 1
}

# Print the complete version of the given python executable
function bes_python_exe_version()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_python_exe_version exe"
    return 1
  fi
  local _exe="${1}"
  local _version=$(${_exe} --version 2>&1 | awk '{ print $2; }')
  echo "${_version}"
  return 0
}

# Install the given python version or do nothing if already installed
function bes_python_install()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_python_install version"
    return 1
  fi
  local _version=${1}
  if bes_has_python ${_version}; then
    return 0
  local _system=$(bes_system)
  case ${_system} in
    macos)
      _rv=$(_bes_variable_map_macos ${_var_name})
      ;;
    *)
      bes_message "Unsupported system: ${_system}"
      ;;
  esac
    
  fi
}

function _bes_python_macos_install()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: _bes_python_install_macos version"
    return 1
  fi
  local _version=${1}
  local _url=https://www.python.org/ftp/python/${_version}/python-${_version}-macosx10.9.pkg
}

# Return 0 if the given python executable is the sytem python that comes with macos
function _bes_python_macos_is_system_python()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: _bes_python_macos_is_system_python exe"
    return 1
  fi
  local _exe=${1}
  local _url=https://www.python.org/ftp/python/${_version}/python-${_version}-macosx10.9.pkg
}

_bes_trace_file "end"
