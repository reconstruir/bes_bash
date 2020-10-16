#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

# Functions to deal with pipenv

_bes_trace_file "begin"

# Call pipenv with a specific root
function bes_pipenv_call()
{
  if [[ $# < 1 ]]; then
    echo "usage: bes_pipenv_call python_exe project_dir <args>"
    return 1
  fi
  local _python_exe="${1}"
  shift
  bes_python_check_python_exe bes_pipenv_call "${_python_exe}"

  local _project_dir="${1}"
  shift
  local _user_base_dir="${_project_dir}"/.py-user-base
  local _fake_home_dir="${_project_dir}"/.home
  local _pip_cache_dir="${_project_dir}"/.pip-cache
  local _pipenv_cache_dir="${_project_dir}"/.pipenv-cache
  
  local _tmp_log=/tmp/tmp_bes_pipenv_call_$$.log
  rm -f "${_tmp_log}"

  ( cd "${_project_dir}" && HOME="${_fake_home_dir}" WORKON_HOME="${_project_dir}" PIPENV_VENV_IN_PROJECT=1 PIP_CACHE_DIR="${_pip_cache_dir}" PIPENV_CACHE_DIR="${_pipenv_cache_dir}" bes_pip_call_program "${_python_exe}" "${_user_base_dir}" pipenv --python "${_python_exe}" ${1+"$@"} >& "${_tmp_log}" )
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
  if [[ $# != 2 ]]; then
    bes_message "Usage: bes_pipenv_exe python_exe project_dir"
    return 1
  fi
  local _python_exe="${1}"
  if ! bes_path_is_abs "${_python_exe}"; then
    bes_message "bes_pipenv_exe: python_exe needs to be an absolute path"
    return 1
  fi
  local _user_base_dir="${_project_dir}"/.py-user-base
  local _pipenv_exe="${_user_base_dir}/pipenv"
  echo "${_pipenv_exe}"
  return 0
}

# Retrun 0 if pipenv is found for the given python exe
function bes_pipenv_has_pipenv()
{
  if [[ $# != 2 ]]; then
    bes_message "Usage: bes_pipenv_has_pipenv python_exe project_dir"
    return 1
  fi
  local _python_exe="${1}"
  local _project_dir="${2}"
  if ! bes_path_is_abs "${_python_exe}"; then
    bes_message "bes_pipenv_exe: python_exe needs to be an absolute path"
    return 1
  fi
  local _pipenv_exe="$(bes_pipenv_exe "${_python_exe}" "${_project_dir}")"
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
  if [[ $# != 4 ]]; then
    bes_message "Usage: bes_pipenv_ensure python_exe project_dir pip_version pipenv_version"
    return 1
  fi
  local _python_exe="${1}"
  local _project_dir="${2}"
  local _pip_version=${3}
  local _pipenv_version=${4}
  if ! bes_path_is_abs "${_python_exe}"; then
    bes_message "bes_pipenv_exe: python_exe needs to be an absolute path"
    return 1
  fi

  local _user_base_dir="${_project_dir}"/.py-user-base
  local _pip_cache_dir="${_project_dir}"/.pip-cache
  local _fake_home_dir="${_project_dir}"/.home
  if ! HOME="${_fake_home_dir}" PIP_CACHE_DIR="${_pip_cache_dir}" bes_pip_ensure "${_python_exe}" "${_user_base_dir}" ${_pip_version}; then
    return 1
  fi

  local _pip_exe="$(bes_pip_exe "${_python_exe}" "${_user_base_dir}")"
  if ! bes_pipenv_has_pipenv "${_python_exe}" "${_project_dir}"; then
    if ! HOME="${_fake_home_dir}" PIP_CACHE_DIR="${_pip_cache_dir}" bes_pip_install_package "${_python_exe}" "${_pip_exe}" pipenv ${_pipenv_version}; then
      return 1
    fi
  fi

  local _pipenv_exe="$(bes_pipenv_exe "${_python_exe}" "${_project_dir}")"
  local _current_pipenv_version="$(bes_pipenv_version "${_pipenv_exe}")"
  if [[ ${_current_pipenv_version} == ${_pipenv_version} ]]; then
    return 0
  fi
  
  if ! HOME="${_fake_home_dir}" PIP_CACHE_DIR="${_pip_cache_dir}" bes_pip_install_package "${_python_exe}" "${_pip_exe}" pipenv ${_pipenv_version}; then
    return 1
  fi
  return 0
}

_bes_trace_file "end"
