#!/bin/bash

function _test_bes_pip_this_dir()
{
  local _this_file
  local _test_bes_pip_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_pip_this_dir="${_this_file%/*}"
  if [ "${_test_bes_pip_this_dir}" == "${_this_file}" ]; then
    _test_bes_pip_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_pip_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_pip_this_dir)"/../bash/bes_shell/bes_shell.sh
source "$(_test_bes_pip_this_dir)"/../bash/bes_shell/bes_python.sh
source "$(_test_bes_pip_this_dir)"/../bash/bes_shell/bes_pip.sh
source "$(_test_bes_pip_this_dir)"/../bash/bes_shell/_bes_python_testing.sh

function test_bes_pip_exe()
{
  local _tmp=/tmp/test_bes_pip_exe$$
  local _fake_python="$(_bes_python_testing_make_testing_python_exe "${_tmp}" fake_python.sh 2.7.666)"
  
  bes_assert "[[ $(bes_pip_exe ${_fake_python}) == ${_tmp}/pip2.7 ]]"

  rm -rf ${_tmp}
}

bes_testing_run_unit_tests
