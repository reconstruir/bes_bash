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
  local _version=$(bes_python_exe_version "${_python_exe}")
  local _pip_basename=pip${_version}
  # Check the python builtin bin dir for pip
  local _builtin_python_bin_dir="$(bes_python_bin_dir "${_python_exe}")"
  local _builtin_pip_abs="${_builtin_python_bin_dir}/${_pip_basename}"
  if [[ -x "${_builtin_pip_abs}" ]]; then
    echo "${_builtin_pip_abs}"
    return 0
  fi
  # Check the python user base bin dir for pip
  local _user_base_python_bin_dir="$(bes_python_user_base_bin_dir "${_python_exe}")"
  local _user_base_pip_abs="${_user_base_python_bin_dir}/${_pip_basename}"
  if [[ -x "${_user_base_pip_abs}" ]]; then
    echo "${_user_base_pip_abs}"
    return 0
  fi
  echo ""
  return 1
}

# Print the full version of pip
function bes_pip_exe_full_version()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_pip_exe_full_version exe"
    return 1
  fi
  local _exe="${1}"
  local _full_version=$(${_exe} --version | ${_BES_AWK_EXE} '{ print $2; }')
  echo "${_full_version}"
  return 0
}

# Install pip for a given python exe
function bes_pip_install()
{
  if [[ $# != 1 ]]; then
    echo "usage: bes_pip_install python_exe"
    return 1
  fi
  local _python_exe="${1}"
  if ! bes_path_is_abs "${_python_exe}"; then
    bes_message "bes_pip_install: python_exe needs to be an absolute path"
    return 1
  fi
  local _version=$(bes_python_exe_version "${_python_exe}")
  
  local _GET_PIP_URL="https://bootstrap.pypa.io/get-pip.py"
  local _python_exe="${1}"
  local _python_version="${2}"
  local _tmp_get_pip=/tmp/tmp_get_pip_$$.py
  rm -f "${_tmp_get_pip}"
  echo "${_tmp_get_pip}"
  local _python_user_base_dir="$(bes_python_user_base_dir "${_python_exe}")"
  echo ${_python_user_base_dir}
  if ! bes_download "${_GET_PIP_URL}" "${_tmp_get_pip}"; then
    bes_message "Failed to download ${_GET_PIP_URL}"
    return 1
  fi
  bes_message "Installed pip for ${_python_exe}"
  local _pip_exe_basename=pip${_python_version}
  if ! bes_has_program ${_pip_exe_basename}; then
    bes_message "fuck"
    return 1
  fi
  return 0
}

# Return 0 if pip matching the version of the given python exe is found
function bes_pip_has_pip()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_pip_has_pip exe"
    return 1
  fi
  local _exe="${1}"
  if ! bes_path_is_abs "${_exe}"; then
    bes_message "bes_pip_has_pip: exe needs to be an absolute path"
    return 1
  fi
  local _pip_exe="$(bes_pip_exe "${_exe}")"
  if [[ -x "${_pip_exe}" ]]; then
    return 0
  fi
  return 1
}

# Call pipenv within the current devenv.  Need to source devenv/py{2.7,3.7,3.8}/enable.bash first"
function eca_pipenv()
{
  local _this_dir="$(_eca_this_dir_devenv_setup_dot_bash)"
  if [[ -z "${EGO_DEVENV_VERSION}" ]]; then
    echo "EGO_DEVENV_VERSION not set.  source ${_this_dir}/py{2.7,3.7,3.8}/enable.bash first"
    return 1
  fi
  local _root_dir="$(bes_abs_path ${_this_dir}/..)"
  local _work_dir=${_root_dir}/devenv/py${EGO_DEVENV_VERSION}
  pushd ${_work_dir} >& /dev/null
  python${EGO_DEVENV_VERSION} $(which pipenv) ${1+"$@"}
  local _rv=$?
  popd >& /dev/null
  return ${_rv}
}

_bes_trace_file "end"
