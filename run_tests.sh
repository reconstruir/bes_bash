#!/bin/bash

function main()
{
  local _test_dir=$(_bes_test_this_dir)/tests
  local _result=0
  local _test_file
  local _tests

  local _temp_home=/tmp/run_test_temp_home_$$
  mkdir -p "${_temp_home}"

  if [[ $# > 0 ]]; then
    _tests=${1+"$@"}
  else
    _tests="${_test_dir}/*.sh"
  fi
  for _test_file in ${_tests}; do
    HOME="${_temp_home}" ${_test_file}
    local _rv=$?
    if [[ ${_rv} != 0 ]]; then
      echo "FAILED: ${_test_file}"
      _result=1
    else
      echo "PASSED: ${_test_file}"
    fi
  done
  local _side_effect
  for _side_effect in $(find "${_temp_home}" -type f); do
    echo "SIDE_EFFECT: ${_side_effect}"
    _result=1
  done

  rm -rf "${_temp_home}"

  if [[ ${_result} == 0 ]]; then
    echo "PASSED: all tests passed"
  else
    echo "FAILED: some tests failed"
  fi
  
  return ${_result}
}

function _bes_test_this_dir()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  return 0
}

main ${1+"$@"}
