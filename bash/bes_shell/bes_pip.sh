#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

# Functions to deal with pip

_bes_trace_file "begin"

# Print the absolute path to the pip exe that corresponds to the given python exe
function bes_pip_exe()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_pip_exe exe"
    return 1
  fi
  local _exe="${1}"
  if ! bes_path_is_abs "${_exe}"; then
    bes_message "bes_pip_exe: exe needs to be an absolute path"
    return 1
  fi
  local _version=$(bes_python_exe_version "${_exe}")
  local _pip_basename=pip${_version}
  local _python_dir="$(dirname "${_exe}")"
  local _pip_abs="${_python_dir}/${_pip_basename}"
  echo "${_pip_abs}"
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
