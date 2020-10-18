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
  local _tmp=/tmp/test_${_label}_$$.cfg
  rm -f "${_tmp}"
  echo "${_content}" > "${_tmp}"
  echo "${_tmp}"
  return 0
}

function test_bes_config_get()
{
  local _tmp_config=$(_make_test_config bes_config_get "\
[drink]
  type: wine
  name: barolo
  region: piedmont

[cheese]
  name: cheddar
  color: yellow
")
  local _value="$(bes_config_get "${_tmp_config}" cheese name)"
  bes_assert "[[ ${_value} == cheddar ]]"

  rm -rf ${_tmp_config}
}

bes_testing_run_unit_tests
