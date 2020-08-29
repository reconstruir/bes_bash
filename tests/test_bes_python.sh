#!/bin/bash

function _test_bes_python_this_dir()
{
  local _this_file
  local _test_bes_python_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_python_this_dir="${_this_file%/*}"
  if [ "${_test_bes_python_this_dir}" == "${_this_file}" ]; then
    _test_bes_python_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_python_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source $(_test_bes_python_this_dir)/../bash/bes_shell/bes_shell.sh
source $(_test_bes_python_this_dir)/../bash/bes_shell/bes_python.sh

function test_bes_has_python()
{
  bes_assert "[[ $(bes_testing_call_function bes_has_python bad ) == 1 ]]"
}

bes_testing_run_unit_tests
