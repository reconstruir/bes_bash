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

source "$(_test_bes_string_this_dir)"/../bash/bes_shell/bes_shell.sh
source "$(_test_bes_string_this_dir)"/../bash/bes_shell/bes_string.bash

function test_bes_string_strip_head()
{
  function _call_bes_string_strip_head()
  {
    bes_string_strip_head "${1}" | tr ' ' '_'
  }
  bes_assert "[[ $(_call_bes_string_strip_head "  foo") == foo ]]"
  bes_assert "[[ $(_call_bes_string_strip_head "  foo ") == foo_ ]]"
  bes_assert "[[ $(_call_bes_string_strip_head " foo ") == foo_ ]]"
  bes_assert "[[ $(_call_bes_string_strip_head "f oo") == f_oo ]]"
  bes_assert "[[ $(_call_bes_string_strip_head " f oo") == f_oo ]]"
  bes_assert "[[ $(_call_bes_string_strip_head " f oo ") == f_oo_ ]]"
  bes_assert "[[ $(_call_bes_string_strip_head "") == ]]"
}

function test_bes_string_strip_tail()
{
  function _call_bes_string_strip_tail()
  {
    bes_string_strip_tail "${1}" | tr ' ' '_'
  }
  bes_assert "[[ $(_call_bes_string_strip_tail "  foo") == __foo ]]"
  bes_assert "[[ $(_call_bes_string_strip_tail "  foo ") == __foo ]]"
  bes_assert "[[ $(_call_bes_string_strip_tail " foo ") == _foo ]]"
  bes_assert "[[ $(_call_bes_string_strip_tail "f oo") == f_oo ]]"
  bes_assert "[[ $(_call_bes_string_strip_tail " f oo ") == _f_oo ]]"
  bes_assert "[[ $(_call_bes_string_strip_tail "") == ]]"
}

function test_bes_string_strip()
{
  function _call_bes_string_strip()
  {
    bes_string_strip "${1}" | tr ' ' '_'
  }
  bes_assert "[[ $(_call_bes_string_strip "  foo") == foo ]]"
  bes_assert "[[ $(_call_bes_string_strip "  foo ") == foo ]]"
  bes_assert "[[ $(_call_bes_string_strip " foo ") == foo ]]"
  bes_assert "[[ $(_call_bes_string_strip "f oo") == f_oo ]]"
  bes_assert "[[ $(_call_bes_string_strip " f oo ") == f_oo ]]"
  bes_assert "[[ $(_call_bes_string_strip "") == ]]"
}

function test_bes_string_partition()
{
  function _part_left()
  {
    bes_string_partition "${1}" ${2} | head -1 | tr ' ' '_'
  }
  function _part_delim()
  {
    bes_string_partition "${1}" ${2} | tail -2 | head -1 | tr ' ' '_'
  }
  function _part_right()
  {
    bes_string_partition "${1}" ${2} | tail -1 | tr ' ' '_'
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
}

bes_testing_run_unit_tests
