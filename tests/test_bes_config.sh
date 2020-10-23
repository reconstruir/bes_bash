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
  local _label="${1}"
  local _content="${2}"
  local _funcname=${FUNCNAME[1]}
  local _tmp=/tmp/test_${_funcname}_${_label}_$$.cfg
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

function test__bes_config_parse_entry()
{
  function _call_parse_entry()
  {
    local _value="$(_bes_config_parse_entry "${1}")"
    _bes_config_parse_entry "${1}" >& /dev/null
    local _rv=$?
    echo ${_rv}:"${_value}"
    return 0
  }

  bes_assert "[[ $(_call_parse_entry "  name: cheddar") == 0:name:cheddar ]]"
  bes_assert "[[ $(_call_parse_entry "  foo name: cheddar") == 0:foo@SPACE@name:cheddar ]]"
  bes_assert "[[ $(_call_parse_entry "  foo name: cheddar is nice") == 0:foo@SPACE@name:cheddar@SPACE@is@SPACE@nice ]]"
  bes_assert "[[ $(_call_parse_entry "  foo: bar: baz") == 0:foo:bar@COLON@@SPACE@baz ]]"
}

function test_bes_config_get()
{
  local _tmp_config=$(_make_test_config one "\
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
  local _tmp_config=$(_make_test_config one "\
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
  local _tmp_config=$(_make_test_config one "\
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
  local _tmp_config=$(_make_test_config one "\
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
  local _tmp_config=$(_make_test_config one "\
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
  local _tmp_config1=$(_make_test_config one "\
[drink]
  type: wine
  name: barolo
  region: piedmont

[cheese]
  name: cheddar
  color: yellow
")

  bes_config_set "${_tmp_config1}" cheese name brie

  local _tmp_config2=$(_make_test_config two "\
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

function test__bes_config_tokenize()
{
  local _tmp_config=$(_make_test_config one "\
[drink]
  type: wine
  name: barolo
  region: piedmont

[cheese]
  name: cheddar
  color: yellow
")

  local _expected_tokens=( \
"token_section:1:drink::" \
"token_entry:2:@SPACE@@SPACE@type@COLON@@SPACE@wine:type:wine" \
"token_entry:3:@SPACE@@SPACE@name@COLON@@SPACE@barolo:name:barolo" \
"token_entry:4:@SPACE@@SPACE@region@COLON@@SPACE@piedmont:region:piedmont" \
"token_whitespace:5:::" \
"token_section:6:cheese::" \
"token_entry:7:@SPACE@@SPACE@name@COLON@@SPACE@cheddar:name:cheddar" \
"token_entry:8:@SPACE@@SPACE@color@COLON@@SPACE@yellow:color:yellow" \
"token_whitespace:9:::" \
)
  
  local _actual_tokens=( $(_bes_config_tokenize "${_tmp_config}") )
  local _token
  local _num_actual=${#_actual_tokens}
  local _num_expected=${#_expected_tokens}

  bes_assert "[[ ${_num_actual} == ${_num_expected} ]]"

  local _i=0
  while [[ ${_i} -lt ${_num_actual} ]]; do
    local _actual_token=${_actual_tokens[${_i}]}
    local _expected_token=${_expected_tokens[${_i}]}
    bes_assert "[[ ${_actual_token} == ${_expected_token} ]]"
    _i=$(( _i + 1 ))
  done
  
  rm -rf ${_tmp_config}
}

function test_bes_config_has_section()
{
  local _tmp_config=$(_make_test_config one "\
[drink]
  type: wine
  name: barolo
  region: piedmont

[cheese]
  name: cheddar
  color: yellow
")

  bes_assert "[[ $(bes_testing_call_function bes_config_has_section ${_tmp_config} drink) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_config_has_section ${_tmp_config} cheese) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_config_has_section ${_tmp_config} wine) == 1 ]]"

  rm -rf ${_tmp_config}
}

bes_testing_run_unit_tests
