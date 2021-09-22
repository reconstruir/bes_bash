#!/bin/bash

function _test_bes_var_this_dir()
{
  local _this_file
  local _test_bes_var_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_var_this_dir="${_this_file%/*}"
  if [ "${_test_bes_var_this_dir}" == "${_this_file}" ]; then
    _test_bes_var_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_var_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_var_this_dir)"/../bash/bes_shell/bes_shell.bash
bes_import "bes_testing.bash"
bes_import "bes_var.bash"

function test_bes_var_set()
{
  bes_var_set FOO 666
  bes_assert "[ $FOO = 666 ]"
}

function test_bes_var_get()
{
  BAR=667
  v=$(bes_var_get BAR)
  bes_assert "[ $v = 667 ]"
}

bes_testing_run_unit_tests
