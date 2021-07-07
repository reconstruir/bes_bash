#!/bin/bash

function _test_bes_path_this_dir()
{
  local _this_file
  local _test_bes_path_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_path_this_dir="${_this_file%/*}"
  if [ "${_test_bes_path_this_dir}" == "${_this_file}" ]; then
    _test_bes_path_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_path_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_var.bash
source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_log.bash
source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_system.bash
source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_testing.bash
source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_filename.bash

function test_bes_filename_extension()
{
  bes_assert "[ $(bes_filename_extension foo.png) = png ]"
}

bes_testing_run_unit_tests
