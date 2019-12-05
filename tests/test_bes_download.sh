#!/bin/bash

function _test_bes_download_this_dir()
{
  local _this_file
  local _test_bes_download_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_download_this_dir="${_this_file%/*}"
  if [ "${_test_bes_download_this_dir}" == "${_this_file}" ]; then
    _test_bes_download_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_download_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source $(_test_bes_download_this_dir)/../bash/bes_shell/bes_shell.sh
source $(_test_bes_download_this_dir)/../bash/bes_shell/bes_download.sh

function test_download_success()
{
  local _tmp=/tmp/test_download_success_$$
  bes_assert "[[ $(bes_download https://www.example.com ${_tmp} ; echo $? ) == 0 ]]"
  bes_assert "[[ $(test -f ${_tmp} ; echo $? ) == 0 ]]"
  bes_assert "[[ $(grep html ${_tmp} >& /dev/null ; echo $? ) == 0 ]]"
  rm -f "${_tmp}"
}

function test_download_failure()
{
  local _tmp=/tmp/test_download_success_$$
  bes_assert "[[ $(bes_download https://www.example.com/nothere ${_tmp} ; echo $? ) == 1 ]]"
  rm -f "${_tmp}"
}

function test_download_302()
{
  local _tmp=/tmp/test_download_302_$$.tgz
  bes_assert "[[ $(bes_download https://github.com/git-lfs/git-lfs/releases/download/v2.9.1/git-lfs-darwin-amd64-v2.9.1.tar.gz ${_tmp} ; echo $? ) == 0 ]]"
  bes_assert "[[ $(bes_checksum_file sha256 ${_tmp}) == 973b6acb2735016265008b74c2f677ed5c086d2abfef4e77925f00efa4751205 ]]"
  rm -f "${_tmp}"
}

bes_testing_run_unit_tests
