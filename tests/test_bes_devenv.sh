#!/bin/bash

function _test_bes_devenv_this_dir()
{
  local _this_file
  local _test_bes_devenv_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_devenv_this_dir="${_this_file%/*}"
  if [ "${_test_bes_devenv_this_dir}" == "${_this_file}" ]; then
    _test_bes_devenv_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_devenv_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_devenv_this_dir)"/../bash/bes_shell/bes_shell.sh
source "$(_test_bes_devenv_this_dir)"/../bash/bes_shell/bes_python.sh
source "$(_test_bes_devenv_this_dir)"/../bash/bes_shell/bes_download.sh
source "$(_test_bes_devenv_this_dir)"/../bash/bes_shell/bes_pip.sh
source "$(_test_bes_devenv_this_dir)"/../bash/bes_shell/bes_pipenv.sh
source "$(_test_bes_devenv_this_dir)"/../bash/bes_shell/bes_devenv.sh

function test_bes_devenv_ensure()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "bes_pipenv_ensure: skipping because no builtin python found"
    return 0
  fi
  local _tmp=/tmp/test_bes_devenv_ensure_$$

  bes_devenv_ensure "${_builtin_python}" "${_tmp}" 20.2.2 2020.8.13
  local _ensure_rv=$?
  bes_assert "[[ ${_ensure_rv} == 0 ]]"

  rm -rf ${_tmp}
}

bes_testing_run_unit_tests
