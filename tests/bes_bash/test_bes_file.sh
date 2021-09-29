#!/bin/bash

function _test_this_dir()
{
  local _this_file
  local _test_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_this_dir="${_this_file%/*}"
  if [ "${_test_this_dir}" == "${_this_file}" ]; then
    _test_this_dir=.
  fi
  echo $(command cd -P "${_test_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_this_dir)"/../../bash/bes_bash/bes_basic.bash
bes_import "bes_testing.bash"
bes_import "bes_file.bash"

function test_bes_file_dir()
{
  local _tmp="$(bes_testing_make_temp_dir test_bes_file_dir)"
  mkdir -p "${_tmp}/foo"
  bes_assert "[ $(bes_file_dir "${_tmp}/foo/file.txt") = ${_tmp}/foo ]"
  ( cd "${_tmp}" && ln -s foo bar )
  bes_assert "[ $(bes_file_dir "${_tmp}/bar/file.txt") = ${_tmp}/foo ]"
  rm -rf "${_tmp}"
}

function test_bes_file_check()
{
  local _tmp="$(bes_testing_make_temp_dir test_bes_file_check)"
  touch ${_tmp}/kiwi.txt
  bes_assert "[[ $(bes_testing_call_function bes_file_check "${_tmp}/kiwi.txt") == 0 ]]"
  rm -rf "${_tmp}"
}

bes_testing_run_unit_tests
