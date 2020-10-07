#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

# Functions to deal with pipenv

_bes_trace_file "begin"

# Call pipenv with a specific root
function bes_pipenv_call()
{
  if [[ $# < 1 ]]; then
    echo "usage: bes_pipenv_call project_dir <args>"
    return 1
  fi
  local _project_dir="${1}"
  shift
  local _tmp_log=/tmp/tmp_bes_pipenv_call_$$.log
  rm -f "${_tmp_log}"
  ( cd "${_project_dir}" && pipenv ${1+"$@"} >& "${_tmp_log}" )
  local _pipenv_rv=$?
  if [[ ${_pipenv_rv} != 0 ]]; then
    bes_message "failed to call: pipenv "${1+"$@"}
    cat "${_tmp_log}"
    rm -f "${_tmp_log}"
    return ${_pipenv_rv}
  fi
  rm -f "${_tmp_log}"
  return 0
}

# Print the absolute path to the pipenv exe that corresponds to the given python exe
function bes_pipenv_exe()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_pipenv_exe python_exe"
    return 1
  fi
  local _python_exe="${1}"
  if ! bes_path_is_abs "${_python_exe}"; then
    bes_message "bes_pipenv_exe: python_exe needs to be an absolute path"
    return 1
  fi
  if ! bes_pip_has_pip "${_python_exe}"; then
    bes_message "pip not installed for ${_python_exe}"
    return 1
  fi
  local _user_base_python_bin_dir="$(bes_python_user_base_bin_dir "${_python_exe}")"
  local _pipenv_exe="${_user_base_python_bin_dir}/pipenv"
  
  if [[ ! -x "${_pipenv_exe}" ]]; then
    echo ""
    return 1
  fi

  echo "${_pipenv_exe}"
  return 0
}

# Retrun 0 if pipenv is found for the given python exe
function bes_pipenv_has_pipenv()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_pipenv_has_pipenv python_exe"
    return 1
  fi
  local _python_exe="${1}"
  if ! bes_path_is_abs "${_python_exe}"; then
    bes_message "bes_pipenv_exe: python_exe needs to be an absolute path"
    return 1
  fi
  local _pipenv_exe="$(bes_pipenv_exe "${_python_exe}")"
  if [[ ! -x "${_pipenv_exe}" ]]; then
    return 1
  fi
  return 0
}

# Print the version of the given pipenv exe
function bes_pipenv_version()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_pipenv_version pipenv_exe"
    return 1
  fi
  local _pipenv_exe="${1}"
  if [[ ! -x "${_pipenv_exe}" ]]; then
    bes_message "bes_pipenv_version: failed to execute: ${_pipenv_exe}"
    return 1
  fi
  local _pipenv_version="$("${_pipenv_exe}" --version | awk '{ print $3; }')"
  echo ${_pipenv_version}
  return 0
}

# Ensure pipenv is installed
function bes_pipenv_ensure()
{
  if [[ $# != 2 ]]; then
    bes_message "Usage: bes_pipenv_ensure python_exe pipenv_version"
    return 1
  fi
  local _python_exe="${1}"
  local _pipenv_version=${2}
  if ! bes_path_is_abs "${_python_exe}"; then
    bes_message "bes_pipenv_exe: python_exe needs to be an absolute path"
    return 1
  fi
  if ! bes_pip_has_pip "${_python_exe}"; then
    bes_message "pip not installed for ${_python_exe}"
    return 1
  fi
  local _pip_exe="$(bes_pip_exe "${_python_exe}")"
  if ! bes_pipenv_has_pipenv "${_python_exe}"; then
    local _tmp_log=/tmp/tmp_bes_pipenv_ensure_install_$$.log
    if ! ${_pip_exe} install pipenv==${_pipenv_version} >& "${_tmp_log}"; then
      bes_message "failed to install pipenv for pip ${_pip_exe}"
      cat "${_tmp_log}"
      rm -f "${_tmp_log}"
      return 1
    fi
  fi

  if bes_pipenv_has_pipenv "${_python_exe}"; then
    local _pipenv_exe="$(bes_pipenv_exe "${_python_exe}")"
    local _current_pipenv_version="$(bes_pipenv_version "${_pipenv_exe}")"
    if [[ ${_current_pipenv_version} == ${_pipenv_version} ]]; then
      return 0
    fi
  fi
  
  if ! bes_pip_install_package "${_pip_exe}" pipenv ${_pip_version}; then
    return 1
  fi
  
  return 0
}

_bes_trace_file "end"
