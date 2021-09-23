#!/bin/bash

function _test_bes_list_this_dir()
{
  local _this_file
  local _test_bes_list_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_list_this_dir="${_this_file%/*}"
  if [ "${_test_bes_list_this_dir}" == "${_this_file}" ]; then
    _test_bes_list_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_list_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_list_this_dir)"/../bash/bes_shell/bes_shell.bash
bes_import "bes_list.bash"
bes_import "bes_testing.bash"

function test_bes_is_in_list()
{
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list foo foo bar) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list kiwi foo bar) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list "foo " foo bar) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list "foo " "foo " bar) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list foo foo) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list foo bar) == 1 ]]"
}  

bes_testing_run_unit_tests
