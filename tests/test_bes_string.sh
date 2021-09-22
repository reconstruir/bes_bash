#!/bin/bash

function _test_bes_string_this_dir()
{
  local _this_file
  local _test_bes_string_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_string_this_dir="${_this_file%/*}"
  if [ "${_test_bes_string_this_dir}" == "${_this_file}" ]; then
    _test_bes_string_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_string_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_string_this_dir)"/../bash/bes_shell/bes_shell.bash
bes_import "bes_testing.bash"
bes_import "bes_string.bash"

function test_bes_str_strip_head()
{
  function _call_bes_str_strip_head()
  {
    bes_str_strip_head "${1}" | tr ' ' '_'
  }
  bes_assert "[[ $(_call_bes_str_strip_head "  foo") == foo ]]"
  bes_assert "[[ $(_call_bes_str_strip_head "  foo ") == foo_ ]]"
  bes_assert "[[ $(_call_bes_str_strip_head " foo ") == foo_ ]]"
  bes_assert "[[ $(_call_bes_str_strip_head "f oo") == f_oo ]]"
  bes_assert "[[ $(_call_bes_str_strip_head " f oo") == f_oo ]]"
  bes_assert "[[ $(_call_bes_str_strip_head " f oo ") == f_oo_ ]]"
  bes_assert "[[ $(_call_bes_str_strip_head "") == ]]"
}

function test_bes_str_strip_tail()
{
  function _call_bes_str_strip_tail()
  {
    bes_str_strip_tail "${1}" | tr ' ' '_'
  }
  bes_assert "[[ $(_call_bes_str_strip_tail "  foo") == __foo ]]"
  bes_assert "[[ $(_call_bes_str_strip_tail "  foo ") == __foo ]]"
  bes_assert "[[ $(_call_bes_str_strip_tail " foo ") == _foo ]]"
  bes_assert "[[ $(_call_bes_str_strip_tail "f oo") == f_oo ]]"
  bes_assert "[[ $(_call_bes_str_strip_tail " f oo ") == _f_oo ]]"
  bes_assert "[[ $(_call_bes_str_strip_tail "") == ]]"
}

function test_bes_str_strip()
{
  function _call_bes_str_strip()
  {
    bes_str_strip "${1}" | tr ' ' '_'
  }
  bes_assert "[[ $(_call_bes_str_strip "  foo") == foo ]]"
  bes_assert "[[ $(_call_bes_str_strip "  foo ") == foo ]]"
  bes_assert "[[ $(_call_bes_str_strip " foo ") == foo ]]"
  bes_assert "[[ $(_call_bes_str_strip "f oo") == f_oo ]]"
  bes_assert "[[ $(_call_bes_str_strip " f oo ") == f_oo ]]"
  bes_assert "[[ $(_call_bes_str_strip "") == ]]"
}

function test_bes_str_partition()
{
  function _part_left()
  {
    bes_str_partition "${1}" ${2} | head -1 | tr ' ' '_'
  }
  function _part_delim()
  {
    bes_str_partition "${1}" ${2} | tail -2 | head -1 | tr ' ' '_'
  }
  function _part_right()
  {
    bes_str_partition "${1}" ${2} | tail -1 | tr ' ' '_'
  }
  function _part()
  {
    local _left=$(_part_left "${1}" ${2})
    local _delim=$(_part_delim "${1}" ${2})
    local _right=$(_part_right "${1}" ${2})
    echo "${_left}:${_delim}:${_right}"
  }
  
  bes_assert "[[ $( _part "key=value" "=") == key:=:value ]]"
  bes_assert "[[ $( _part "   key: pvalue with spaces" ":") == ___key:::_pvalue_with_spaces ]]"
  bes_assert "[[ $( _part "key=value" ":") == key=value:: ]]"
  bes_assert "[[ $( _part "=value only" "=") == :=:value_only ]]"
  bes_assert "[[ $( _part "=" "=") == :=: ]]"
  bes_assert "[[ $( _part "key with spaces=value" "=") == key_with_spaces:=:value ]]"
}

function test_bes_str_to_lower()
{
  bes_assert "[[ $(bes_str_to_lower FoO) == foo ]]"
  bes_assert "[[ $(bes_str_to_lower FOO) == foo ]]"
  bes_assert "[[ $(bes_str_to_lower foo) == foo ]]"
}  

function test_bes_str_split()
{
  bes_assert "[ $(bes_str_split a:b:c : | tr ' ' '_') = 'a_b_c' ]"
  bes_assert "[ $(bes_str_split a\ :b:c : | tr ' ' '_') = 'a__b_c' ]"
}

function test_bes_str_is_integer()
{
  bes_assert "[[ $(bes_testing_call_function bes_str_is_integer 0 ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_is_integer 1 ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_is_integer foo ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_is_integer 1.0 ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_is_integer 1a ) == 1 ]]"
}

function test_bes_str_starts_with()
{
  bes_assert "[[ $(bes_testing_call_function bes_str_starts_with foo/bar foo ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_starts_with foo/bar foo/ ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_starts_with foo/bar foo/bar ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_starts_with foo/bar f ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_starts_with foo/bar food ) == 1 ]]"
}

function test_bes_str_ends_with()
{
  bes_assert "[[ $(bes_testing_call_function bes_str_ends_with foo/bar foo ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_ends_with foo/bar bar ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_ends_with foo/bar foo/bar ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_ends_with foo/bar r ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_ends_with foo/bar /bar ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_ends_with foo/bar bart ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_ends_with foo.o \\.o ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_ends_with foo.so \\.o ) == 1 ]]"
}

function test_bes_str_remove_head()
{
  bes_assert "[ $(bes_str_remove_head /rel/fruit/1.2.3 /rel/fruit/) = 1.2.3 ]"
  bes_assert "[ $(bes_str_remove_head /rel/fruit/1.2.3 /rel/fruit) = /1.2.3 ]"
  bes_assert "[ $(bes_str_remove_head /rel/fruit/1.2.3 /rel/cheese) = /rel/fruit/1.2.3 ]"
  bes_assert "[ $(bes_str_remove_head /rel/fruit/1.2.3 '') = /rel/fruit/1.2.3 ]"
  bes_assert "[ $(bes_str_remove_head /rel/fruit/1.2.3 /rel/fruit/1.2.3) =  ]"
}

function test_bes_str_remove_tail()
{
  bes_assert "[ $(bes_str_remove_tail /rel/fruit/1.2.3 1.2.3) = /rel/fruit/ ]"
  bes_assert "[ $(bes_str_remove_tail /rel/fruit/1.2.3 1.2.3.4) = /rel/fruit/1.2.3 ]"
  bes_assert "[ $(bes_str_remove_tail /rel/fruit/1.2.3 '') = /rel/fruit/1.2.3 ]"
  bes_assert "[ $(bes_str_remove_tail /rel/fruit/1.2.3 /rel/fruit/1.2.3) =  ]"
}

bes_testing_run_unit_tests
