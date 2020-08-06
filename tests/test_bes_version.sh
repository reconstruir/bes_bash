#!/bin/bash

function _test_bes_version_this_dir()
{
  local _this_file
  local _test_bes_version_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_version_this_dir="${_this_file%/*}"
  if [ "${_test_bes_version_this_dir}" == "${_this_file}" ]; then
    _test_bes_version_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_version_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source $(_test_bes_version_this_dir)/../bash/bes_shell/bes_shell.sh
source $(_test_bes_version_this_dir)/../bash/bes_shell/bes_version.sh

function test_bes_git_tag()
{
  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 0 ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 1.0 ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 1.0.0a ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 1.2.3.4 ) == 1 ]]"

  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 0.0.0 ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 1.2.3 ) == 0 ]]"
}

bes_testing_run_unit_tests
