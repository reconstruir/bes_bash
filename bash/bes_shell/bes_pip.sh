#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

# Functions to deal with pip

_bes_trace_file "begin"

# Print the absolute path to the pip exe that corresponds to the given python exe
function bes_pip_exe()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_pip_exe python_exe"
    return 1
  fi
  local _python_exe="${1}"
  if ! bes_path_is_abs "${_python_exe}"; then
    bes_message "bes_pip_exe: python_exe needs to be an absolute path"
    return 1
  fi
  local _python_version=$(bes_python_exe_version "${_python_exe}")
  local _pip_basename=pip${_python_version}

  # First check the python user specific base bin dir for pip
  local _user_base_python_bin_dir="$(bes_python_user_base_bin_dir "${_python_exe}")"
  local _user_base_pip_abs="${_user_base_python_bin_dir}/${_pip_basename}"
  if [[ -x "${_user_base_pip_abs}" ]]; then
    echo "${_user_base_pip_abs}"
    return 0
  fi

  # Check the python builtin bin dir for pip
  local _builtin_python_bin_dir="$(bes_python_bin_dir "${_python_exe}")"
  local _builtin_pip_abs="${_builtin_python_bin_dir}/${_pip_basename}"

  if [[ -x "${_builtin_pip_abs}" ]]; then
    echo "${_builtin_pip_abs}"
    return 0
  fi

  echo ""
  return 1
}

# Print the full version of pip
function bes_pip_exe_version()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_pip_exe_version exe"
    return 1
  fi
  local _exe="${1}"
  local _full_version=$(${_exe} --version | ${_BES_AWK_EXE} '{ print $2; }')
  echo "${_full_version}"
  return 0
}

# Return 0 if pip matching the version of the given python exe is found
function bes_pip_has_pip()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_pip_has_pip python_exe"
    return 1
  fi
  local _python_exe="${1}"
  if ! bes_path_is_abs "${_python_exe}"; then
    bes_message "bes_pip_has_pip: python_exe needs to be an absolute path"
    return 1
  fi
  local _pip_exe="$(bes_pip_exe "${_python_exe}")"
  if [[ -x "${_pip_exe}" ]]; then
    return 0
  fi
  return 1
}

# Install pip for a given python exe
function bes_pip_install()
{
  if [[ $# != 2 ]]; then
    echo "usage: bes_pip_install python_exe pip_version"
    return 1
  fi
  local _python_exe="${1}"
  if ! bes_path_is_abs "${_python_exe}"; then
    bes_message "bes_pip_install: python_exe needs to be an absolute path"
    return 1
  fi
  
  if bes_pip_has_pip "${_python_exe}"; then
    local _pip_exe="$(bes_pip_exe "${_python_exe}")"
    bes_message "pip already installed: ${_pip_exe}"
    return 1
  fi

  local _pip_version="${2}"
  
  local _GET_PIP_URL="https://bootstrap.pypa.io/get-pip.py"
  local _tmp_get_pip_dot_py=/tmp/tmp_bes_pip_install_get_pip_$$.py
  local _tmp_log=/tmp/tmp_bes_pip_install_$$.log
  rm -f "${_tmp_get_pip_dot_py}" "${_tmp_log}"
  if ! bes_download "${_GET_PIP_URL}" "${_tmp_get_pip_dot_py}"; then
    rm -f "${_tmp_get_pip_dot_py}"
    bes_message "Failed to download ${_GET_PIP_URL} to ${_tmp_get_pip_dot_py}"
    return 1
  fi
  if ! "${_python_exe}" ${_tmp_get_pip_dot_py} >& "${_tmp_log}"; then
    bes_message "Failed to install pip"
    cat "${_tmp_log}"
    rm -f "${_tmp_get_pip_dot_py}" "${_tmp_log}"
    return 1
  fi
  rm -f "${_tmp_get_pip_dot_py}" "${_tmp_log}"

  if ! bes_pip_has_pip "${_python_exe}"; then
    bes_message "pip install succeeded but failing to find pip afterwards"
    return 1
  fi

  bes_pip_update "${_python_exe}" ${_pip_version}
  
  return 0
}

# Update pip to specific version
function bes_pip_update()
{
  if [[ $# != 2 ]]; then
    echo "usage: bes_pip_update python_exe pip_version"
    return 1
  fi
  local _python_exe="${1}"
  local _pip_version="${2}"

  if ! bes_pip_has_pip "${_python_exe}"; then
    bes_message "pip is not installed: ${_python_exe}"
    return 1
  fi

  local _pip_exe=$(bes_pip_exe "${_python_exe}")
  local _current_pip_version=$(bes_pip_exe_version ${_pip_exe})

  if [[ ${_current_pip_version} == ${_pip_version} ]]; then
    return 0
  fi
  
  local _tmp_log=/tmp/tmp_bes_pip_update_$$.log
  if ! "${_pip_exe}" install pip==${_pip_version} >& "${_tmp_log}"; then
    bes_message "Failed to update pip from ${_pip_current_version} to ${_pip_version}"
    cat "${_tmp_log}"
    rm -f "${_tmp_log}"
    return 1
  fi

  local _new_current_pip_version=$(bes_pip_exe_version ${_pip_exe})
  if [[ ${_new_current_pip_version} != ${_pip_version} ]]; then
    bes_message "Failed to update pip from ${_pip_current_version} to ${_pip_version}"
    return 1
  fi
  
  return 0
}

# Ensure that pip is installed and at the given version
function bes_pip_ensure()
{
  if [[ $# != 2 ]]; then
    echo "usage: bes_pip_ensure python_exe pip_version"
    return 1
  fi
  local _python_exe="${1}"
  if ! bes_path_is_abs "${_python_exe}"; then
    bes_message "bes_pip_ensure: python_exe needs to be an absolute path"
    return 1
  fi
  
  local _pip_version="${2}"

  if ! bes_pip_has_pip "${_python_exe}"; then
    if ! bes_pip_install "${_python_exe}" ${_pip_version}; then
      return 1
    fi
  fi

  bes_pip_update "${_python_exe}" ${_pip_version}
  local _rv=$?
  return ${_rv}
}

##### # Call pipenv within the current devenv.  Need to source devenv/py{2.7,3.7,3.8}/enable.bash first"
##### function eca_pipenv()
##### {
#####   local _this_dir="$(_eca_this_dir_devenv_setup_dot_bash)"
#####   if [[ -z "${EGO_DEVENV_VERSION}" ]]; then
#####     echo "EGO_DEVENV_VERSION not set.  source ${_this_dir}/py{2.7,3.7,3.8}/enable.bash first"
#####     return 1
#####   fi
#####   local _root_dir="$(bes_abs_path ${_this_dir}/..)"
#####   local _work_dir=${_root_dir}/devenv/py${EGO_DEVENV_VERSION}
#####   pushd ${_work_dir} >& /dev/null
#####   python${EGO_DEVENV_VERSION} $(which pipenv) ${1+"$@"}
#####   local _rv=$?
#####   popd >& /dev/null
#####   return ${_rv}
##### }

_bes_trace_file "end"
