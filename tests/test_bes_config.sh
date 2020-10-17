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
source "$(_test_bes_config_this_dir)"/../bash/bes_shell/bes_config.sh

function test_bes_config_get()
{
  local _test_config=${_tmp}/test_config.cfg
  cat > ${_test_config} << EOF
[drink]
  type: wine
  name: barolo
  region: piedmont

[cheese]
  name: cheddar
  color: yellow
EOF

  bes_assert "[[ $(bes_config_get ${_test_config} drink type) == wine ]]"

  rm -rf ${_tmp}
}

bes_testing_run_unit_tests
