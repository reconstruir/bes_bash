#!/bin/bash

function _test_bes_pipenv_this_dir()
{
  local _this_file
  local _test_bes_pipenv_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_pipenv_this_dir="${_this_file%/*}"
  if [ "${_test_bes_pipenv_this_dir}" == "${_this_file}" ]; then
    _test_bes_pipenv_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_pipenv_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/bes_shell.sh
source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/bes_python.sh
source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/bes_download.sh
source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/bes_pip.sh
source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/bes_pipenv.sh
source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/_bes_python_testing.sh

function xtest_bes_pipenv_call()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "test_bes_pip_ensure: skipping because no builtin python found"
    return 0
  fi
  if bes_pip_has_pip ${_builtin_python}; then
    bes_message "test_bes_pip_ensure: skipping because pip already found"
    return 0
  fi

  local _tmp=/tmp/test_bes_pipenv_call$$

  local _PIP_VERSION=20.2.2
  export PYTHONUSERBASE="${_tmp}"
  bes_pip_ensure ${_builtin_python} ${_PIP_VERSION}
  local _ensure_rv=$?
  
  bes_assert "[[ ${_ensure_rv} == 0 ]]"

  rm -rf ${_tmp}
}

function test_bes_pipenv_ensure()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "bes_pipenv_ensure: skipping because no builtin python found"
    return 0
  fi
  local _tmp=/tmp/test_bes_pipenv_ensure_$$

  BES_PIP_EXTRA_ARGS="--no-cache-dir" bes_pipenv_ensure "${_builtin_python}" "${_tmp}" 20.2.2 2020.8.13
  local _ensure_rv=$?
  bes_assert "[[ ${_ensure_rv} == 0 ]]"

#####  
######  bes_assert "[[ $(bes_testing_call_function bes_pip_has_pip ${_builtin_python} ) == 1 ]]"
#####
#####  local _PIP_VERSION1=20.2.2
#####  
#####  export PYTHONUSERBASE="${_tmp}"
#####  bes_pip_ensure ${_builtin_python} ${_PIP_VERSION1}
#####
#####  bes_assert "[[ $(bes_testing_call_function bes_pip_has_pip ${_builtin_python} ) == 0 ]]"
#####  
#####  bes_assert "[[ $(bes_testing_call_function bes_pipenv_has_pipenv ${_builtin_python} ) == 1 ]]"
#####
#####  local _PIPENV_VERSION=2020.8.13
#####  bes_pipenv_ensure "${_builtin_python}" ${_PIPENV_VERSION}
#####  local _ensure_rv=$?
#####
#####  bes_assert "[[ ${_ensure_rv} == 0 ]]"
#####
#####  local _pipenv_exe=$(bes_pipenv_exe "${_builtin_python}")
#####  bes_assert "[[ ${_pipenv_exe} == ${_tmp}/bin/pipenv ]]"
#####  
#####  local _pipenv_version=$(bes_pipenv_version "${_pipenv_exe}")
#####  bes_assert "[[ ${_pipenv_version} == ${_PIPENV_VERSION} ]]"
#####  
#####  unset PYTHONUSERBASE
  
  rm -rf ${_tmp}
}

function test_bes_pipenv_call()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "bes_pipenv_call: skipping because no builtin python found"
    return 0
  fi

  local _tmp=/tmp/test_bes_pipenv_call_$$

  BES_PIP_EXTRA_ARGS="--no-cache-dir" bes_pipenv_ensure "${_builtin_python}" "${_tmp}" 20.2.2 2020.8.13
  local _ensure_rv=$?
  bes_assert "[[ ${_ensure_rv} == 0 ]]"

  bes_pipenv_call "${_builtin_python}" "${_tmp}" --version
  
  rm -rf ${_tmp}
}

bes_testing_run_unit_tests
