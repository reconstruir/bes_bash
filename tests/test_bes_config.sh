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

function test__bes_config_line_type()
{
  bes_assert "[[ $(_bes_config_line_type [foo]) == section ]]"
  bes_assert "[[ $(_bes_config_line_type "[foo] # foo") == section ]]"
  bes_assert "[[ $(_bes_config_line_type "# foo") == comment ]]"
  bes_assert "[[ $(_bes_config_line_type "  # foo") == comment ]]"
  bes_assert "[[ $(_bes_config_line_type "") == whitespace ]]"
  bes_assert "[[ $(_bes_config_line_type "  ") == whitespace ]]"
  bes_assert "[[ $(_bes_config_line_type "foo") == entry ]]"
  bes_assert "[[ $(_bes_config_line_type "  foo") == entry ]]"
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

bes_testing_run_unit_tests
