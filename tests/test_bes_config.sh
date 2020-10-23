#!/bin/bash

function _test_bes_config_this_dir()
{
  local _this_file
  local _test_bes_config_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_config_this_dir="${_this_file%/*}"
  if [ "${_test_bes_config_this_dir}" == "${_this_file}" ]; then
    _test_bes_config_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_config_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_config_this_dir)"/../bash/bes_shell/bes_shell.sh
source "$(_test_bes_config_this_dir)"/../bash/bes_shell/bes_string.bash
source "$(_test_bes_config_this_dir)"/../bash/bes_shell/bes_config.bash

function _make_test_config()
{
  local _content="${1}"
  local _label=${FUNCNAME[1]}
  local _tmp=/tmp/test_${_label}_$$.cfg
  rm -f "${_tmp}"
  echo "${_content}" > "${_tmp}"
  echo "${_tmp}"
  return 0
}

function test__bes_config_token_type()
{
  bes_assert "[[ $(_bes_config_token_type [foo]) == token_section ]]"
  bes_assert "[[ $(_bes_config_token_type "[foo] # foo") == token_section ]]"
  bes_assert "[[ $(_bes_config_token_type "# foo") == token_comment ]]"
  bes_assert "[[ $(_bes_config_token_type "  # foo") == token_comment ]]"
  bes_assert "[[ $(_bes_config_token_type "") == token_whitespace ]]"
  bes_assert "[[ $(_bes_config_token_type "  ") == token_whitespace ]]"
  bes_assert "[[ $(_bes_config_token_type "foo") == token_entry ]]"
  bes_assert "[[ $(_bes_config_token_type "  foo") == token_entry ]]"
}

function test__bes_config_parse_section_name()
{
  function _call_parse_section_name()
  {
    local _value="$(_bes_config_parse_section_name "${1}" | tr ' ' '_')"
    _bes_config_parse_section_name "${1}" >& /dev/null
    local _rv=$?
    echo ${_rv}:"${_value}"
    return ${_rv}
  }

  bes_assert "[[ $(_call_parse_section_name "[foo]") == 0:foo ]]"
  bes_assert "[[ $(_call_parse_section_name "[foo bar]") == 0:foo_bar ]]"
  bes_assert "[[ $(_call_parse_section_name "[]") == 1: ]]"
  bes_assert "[[ $(_call_parse_section_name "") == 1: ]]"
  bes_assert "[[ $(_call_parse_section_name "foo") == 1: ]]"
}

function xtest__bes_config_parse_entry()
{
  function _call_parse_entry()
  {
    local _left="$(bes_string_partition "${1}" ":" | head -1)"
    local _delim="$(bes_string_partition "${1}" ":" | tail -2 | head -1)"
    local _right="$(bes_string_partition "${1}" ":" | tail -1)"
    
    local _value="$(_bes_config_parse_entry "${1}")"
    _bes_config_parse_entry "${1}" >& /dev/null
    local _rv=$?
    echo ${_rv}:"${_value}"
    return ${_rv}
  }

  bes_assert "[[ $(_call_parse_entry "  cheese: brie") == 0:cheese:brie ]]"
}

function test_bes_config_get()
{
  local _tmp_config=$(_make_test_config "\
[drink]
  type: wine
  name: barolo
  region: piedmont

[cheese]
  name: cheddar
  color: yellow
")
  local _value="$(bes_config_get "${_tmp_config}" cheese name)"
  local _rv=$?
  bes_assert "[[ ${_rv} == 0 ]]"
  bes_assert "[[ ${_value} == cheddar ]]"

  rm -rf ${_tmp_config}
}

function test_bes_config_get_with_no_space()
{
  local _tmp_config=$(_make_test_config "\
[drink]
type: wine
name: barolo
region: piedmont

[cheese]
name: cheddar
color: yellow
")
  local _value="$(bes_config_get "${_tmp_config}" cheese name)"
  local _rv=$?
  bes_assert "[[ ${_rv} == 0 ]]"
  bes_assert "[[ ${_value} == cheddar ]]"

  _value="$(bes_config_get "${_tmp_config}" cheese color)"
  _rv=$?
  bes_assert "[[ ${_rv} == 0 ]]"
  bes_assert "[[ ${_value} == yellow ]]"
  
  rm -rf ${_tmp_config}
}

function test_bes_config_get_with_comments()
{
  local _tmp_config=$(_make_test_config "\
# foo1
[drink]
  type: wine
  # foo2
  name: barolo
  region: piedmont
# foo3

  # foo4
[cheese]
  name: cheddar
  color: yellow
#foo4
")
  local _value="$(bes_config_get "${_tmp_config}" cheese name)"
  local _rv=$?
  bes_assert "[[ ${_rv} == 0 ]]"
  bes_assert "[[ ${_value} == cheddar ]]"

  _value="$(bes_config_get "${_tmp_config}" cheese color)"
  _rv=$?
  bes_assert "[[ ${_rv} == 0 ]]"
  bes_assert "[[ ${_value} == yellow ]]"
  
  rm -rf ${_tmp_config}
}

function test_bes_config_get_dup_key()
{
  local _tmp_config=$(_make_test_config "\
[drink]
  type: wine
  name: barolo
  region: piedmont

[cheese]
  name: cheddar
  color: yellow
  name: brie
")
  local _value="$(bes_config_get "${_tmp_config}" cheese name)"
  local _rv=$?
  bes_assert "[[ ${_rv} == 0 ]]"
  bes_assert "[[ ${_value} == brie ]]"

  rm -rf ${_tmp_config}
}

function test_bes_config_get_not_found()
{
  local _tmp_config=$(_make_test_config "\
[drink]
  type: wine
  name: barolo
  region: piedmont

[cheese]
  name: cheddar
  color: yellow
  name: brie
")

  bes_config_get "${_tmp_config}" fruit name > /dev/null
  local _rv=$?
  bes_assert "[[ ${_rv} == 1 ]]"

  rm -rf ${_tmp_config}
}

function xtest_bes_config_set()
{
  local _tmp_config1=$(_make_test_config "\
[drink]
  type: wine
  name: barolo
  region: piedmont

[cheese]
  name: cheddar
  color: yellow
")
  bes_config_set "${_tmp_config}" cheese name brie

  local _tmp_config2=$(_make_test_config "\
[drink]
  type: wine
  name: barolo
  region: piedmont

[cheese]
  name: brie
  color: yellow
")

  diff "${_tmp_config1}" "${_tmp_config2}" >& /dev/null
  local _rv=$?
  bes_assert "[[ ${_rv} == 0 ]]"

  rm -rf ${_tmp_config1} ${_tmp_config2}
}

function test__bes_config_text_escape()
{
  bes_assert "[[ $(_bes_config_text_escape "foo bar") == foo@SPACE@bar ]]"
  bes_assert "[[ $(_bes_config_text_escape "foo") == foo ]]"
  bes_assert "[[ $(_bes_config_text_escape "") == ]]"
  bes_assert "[[ $(_bes_config_text_escape "foo@FOO@bar") == foo@FOO@bar ]]"
  bes_assert "[[ $(_bes_config_text_escape "key: value with spaces") == key@COLON@@SPACE@value@SPACE@with@SPACE@spaces ]]"
  bes_assert "[[ $(_bes_config_text_escape "foo bar@SPACE@baz") == foo@SPACE@bar%%SPACE%%baz ]]"
}

function test__bes_config_text_unescape()
{
  function _call_unescape()
  {
    _bes_config_text_unescape "${1}" | tr ' ' '_'
  }
  bes_assert "[[ $(_call_unescape foo@SPACE@bar) == foo_bar ]]"
  bes_assert "[[ $(_call_unescape foo) == foo ]]"
  bes_assert "[[ $(_call_unescape "") == ]]"
  bes_assert "[[ $(_call_unescape foo@SPACE@bar ) == "foo_bar" ]]"
  bes_assert "[[ $(_call_unescape foo@FOO@bar ) == "foo@FOO@bar" ]]"
  bes_assert "[[ $(_call_unescape key@COLON@@SPACE@value@SPACE@with@SPACE@spaces ) == key:_value_with_spaces ]]"
  bes_assert "[[ $(_call_unescape foo@SPACE@bar) == foo_bar ]]"
}

bes_testing_run_unit_tests
