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

function test_bes_version_is_valid()
{
  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 0 ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 1.0 ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 1.0.0a ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 1.2.3.4 ) == 1 ]]"

  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 0.0.0 ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_version_is_valid 1.2.3 ) == 0 ]]"
}

function test_bes_version_part_name_is_valid()
{
  bes_assert "[[ $(bes_testing_call_function bes_version_part_name_is_valid major ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_version_part_name_is_valid minor ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_version_part_name_is_valid revision ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_version_part_name_is_valid foo ) == 1 ]]"
}

function test__bes_version_part_index()
{
  bes_assert "[[ $(_bes_version_part_index major ) == 0 ]]"
  bes_assert "[[ $(_bes_version_part_index minor ) == 1 ]]"
  bes_assert "[[ $(_bes_version_part_index revision ) == 2 ]]"
}

function test__bes_version_part_compare()
{
  bes_assert "[[ $(_bes_version_part_compare 0 1 ) == lt ]]"
  bes_assert "[[ $(_bes_version_part_compare 1 0 ) == gt ]]"
  bes_assert "[[ $(_bes_version_part_compare 0 0 ) == eq ]]"

  bes_assert "[[ $(_bes_version_part_compare 9 10 ) == lt ]]"
  bes_assert "[[ $(_bes_version_part_compare 10 9 ) == gt ]]"
  bes_assert "[[ $(_bes_version_part_compare 10 10 ) == eq ]]"
}

function test_bes_version_get_part()
{
  bes_assert "[[ $(bes_version_get_part 1.2.3 major ) == 1 ]]"
  bes_assert "[[ $(bes_version_get_part 1.2.3 minor ) == 2 ]]"
  bes_assert "[[ $(bes_version_get_part 1.2.3 revision ) == 3 ]]"
}

function test_bes_version_bump()
{
  bes_assert "[[ $(bes_version_bump 1.2.3 major ) == 2.2.3 ]]"
  bes_assert "[[ $(bes_version_bump 1.2.3 minor ) == 1.3.3 ]]"
  bes_assert "[[ $(bes_version_bump 1.2.3 revision ) == 1.2.4 ]]"
}

function test_bes_version_bump_prefixed()
{
  bes_assert "[[ $(bes_version_bump_prefixed rel/fruit/1.2.3 rel/fruit/ ) == rel/fruit/1.2.4 ]]"
  bes_assert "[[ $(bes_version_bump_prefixed rel/fruit/0.0.0 rel/fruit/ ) == rel/fruit/0.0.1 ]]"
  bes_assert "[[ $(bes_version_bump_prefixed rel/fruit/1.2.3 rel/fruit/ major ) == rel/fruit/2.2.3 ]]"
  bes_assert "[[ $(bes_version_bump_prefixed rel/fruit/1.2.3 rel/fruit/ minor ) == rel/fruit/1.3.3 ]]"
  bes_assert "[[ $(bes_version_bump_prefixed rel/fruit/1.2.3 rel/fruit/ revision ) == rel/fruit/1.2.4 ]]"
}

function test_bes_version_compare()
{
  bes_assert "[[ $(bes_version_compare 1.0.0 1.0.1 ) == lt ]]"
  bes_assert "[[ $(bes_version_compare 1.0.1 1.0.0 ) == gt ]]"
  bes_assert "[[ $(bes_version_compare 1.0.0 1.0.0 ) == eq ]]"
  bes_assert "[[ $(bes_version_compare 1.0.9 1.0.10 ) == lt ]]"
}

bes_testing_run_unit_tests
