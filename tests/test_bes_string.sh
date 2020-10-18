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

  bes_assert "[[ $( _part_left "   key: pvalue with spaces" ":") == ___key ]]"
  bes_assert "[[ $(_part_delim "   key: pvalue with spaces" ":") == : ]]"
  bes_assert "[[ $(_part_right "   key: pvalue with spaces" ":") == _pvalue_with_spaces ]]"
  
#  local _left="$(bes_string_partition "     key: pvalue with spaces" ":" _x _y _z)" # | head -1 | tr ' ' '_')
#  local _delimiter="$(bes_string_partition "     key: pvalue with spaces" ":" _x _y _z | tail -2 | head -1)"
#  local _tail="$(bes_string_partition "     key: pvalue with spaces" ":" _x _y _z | tail -1)"
#  bes_assert "[[ $(echo ${_left} | tr ' ' '_') == __key ]]"
#  bes_assert "[[ $(echo ${_delimiter}) == : ]]"
#  bes_assert "[[ $(echo ${_right} | tr ' ' '_') == _value_with_spaces ]]"
}

bes_testing_run_unit_tests
