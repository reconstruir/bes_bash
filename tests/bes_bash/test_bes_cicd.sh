#!/bin/bash

function _test_bes_cicd_this_dir()
{
  local _this_file
  local _test_bes_cicd_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_cicd_this_dir="${_this_file%/*}"
  if [ "${_test_bes_cicd_this_dir}" == "${_this_file}" ]; then
    _test_bes_cicd_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_cicd_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_cicd_this_dir)"/../../bash/bes_bash/bes_basic.bash
bes_import "bes_testing.bash"
bes_import "bes_cicd.bash"

function test_bes_cicd_running_under_cicd()
{
  bes_assert "[[ $(bes_testing_call_function bes_cicd_running_under_cicd ) == 1 ]]"
  bes_assert "[[ $(CI=1 bes_testing_call_function bes_cicd_running_under_cicd ) == 0 ]]"
  bes_assert "[[ $(GITLAB_CI=1 bes_testing_call_function bes_cicd_running_under_cicd ) == 0 ]]"
  bes_assert "[[ $(HUDSON_COOKIE=666 bes_testing_call_function bes_cicd_running_under_cicd ) == 0 ]]"
}

bes_testing_run_unit_tests
