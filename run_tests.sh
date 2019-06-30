#!/bin/bash

function main()
{
  local _test_dir=$(_bes_test_this_dir)/tests
  local _result=0
  local _test_file
  local _tests
  if [[ $# > 0 ]]; then
    _tests=${1+"$@"}
  else
    _tests="${_test_dir}/*.sh"
  fi
  for _test_file in ${_tests}; do
    ${_test_file}
    local _rv=$?
    if [[ ${_rv} != 0 ]]; then
      echo "FAILED: ${_test_file}"
      _result=1
    else
      echo "PASSED: ${_test_file}"
    fi
  done
  return ${_result}
}

function _bes_test_this_dir()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  return 0
}

main ${1+"$@"}
