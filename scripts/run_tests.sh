#!/bin/bash

function main()
{
  local _tmp=/tmp/bes_run_tests_tmp_$$
  rm -rf "${_tmp}"
  mkdir -p "${_tmp}"
  local _this_dir="$(_run_tests_this_dir)"
  local _result=0
  local _test_file
  local _tests

  local _temp_home=/tmp/run_test_temp_home_$$
  mkdir -p "${_temp_home}"

  local _pwd=$(pwd)

  local _failed_tests=()
  declare -a _failed_tests

  local _side_effects_log="${_tmp}"/side_effects.log
  
  if [[ $# > 0 ]]; then
    _tests=${1+"$@"}
  else
    _tests="${_this_dir}/../tests/bes_bash/test_bes_*.sh ${_this_dir}/../tests/bes_bash_one_file/test_bes_*.sh"
  fi
  for _test_file in ${_tests}; do
    local _test_file_rel=${_test_file#${_pwd}/}
    HOME="${_temp_home}" ${_test_file}
    local _rv=$?
    if [[ ${_rv} != 0 ]]; then
      echo "FAILED: ${_test_file_rel}"
      _failed_tests+=( ${_test_file_rel} )
      _result=1
    else
      echo "PASSED: ${_test_file_rel}"
    fi
    find "${_temp_home}" -type f | awk '$0="PREFIX"$0' | sed 's@PREFIX@'"SIDE_EFFECT ${_test_file_rel} "'@' >> "${_side_effects_log}"
  done
  if [[ -s "${_side_effects_log}" ]]; then
    cat "${_side_effects_log}"
    _result=1
  fi

  rm -rf "${_temp_home}"

  if [[ ${_result} == 0 ]]; then
    echo "PASSED: all tests passed"
  else
    echo "FAILED: some tests failed"
    local _next_failed_test
    for _failed_test in ${_failed_tests[@]}; do
      echo "FAILED: ${_failed_test}"
    done
  fi

  rm -rf "${_tmp}"

  return ${_result}
}

function _run_tests_this_dir()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  return 0
}

main ${1+"$@"}
