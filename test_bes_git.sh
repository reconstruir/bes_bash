#!/bin/bash

function _this_dir()
{
  local _this_file
  local _this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _this_dir="${_this_file%/*}"
  if [ "${_this_dir}" == "${_this_file}" ]; then
    _this_dir=.
  fi
  echo $(command cd -P "${_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source $(_this_dir)/bash/bes_shell/bes_shell.sh
source $(_this_dir)/bash/bes_shell/bes_git.sh

function test_bes_git_is_repo_true()
{
  local _tmp=/tmp/test_bes_git_is_repo_true_$$
  mkdir -p ${_tmp}
  ( cd ${_tmp} && git init .  >& /dev/null )
  bes_assert "[[ $(bes_testing_call_function bes_git_is_repo ${_tmp}) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_is_repo_false()
{
  local _tmp=/tmp/test_bes_git_is_repo_false_$$
  mkdir -p ${_tmp}
  bes_assert "[[ $(bes_testing_call_function bes_git_is_repo ${_tmp}) == 1 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_repo_has_uncommitted_changes()
{
  local _tmp=/tmp/test_bes_git_is_repo_true_$$
  mkdir -p ${_tmp}
  cd ${_tmp}
  git init . >& /dev/null
  echo "foo.txt\n" > foo.txt
  git add foo.txt >& /dev/null
  git commit -m'test' foo.txt >& /dev/null
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_uncommitted_changes . ) == 1 ]]"
  echo "bar.txt\n" > foo.txt
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_uncommitted_changes . ) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_repo_has_unpushed_changes()
{
  local _tmp_remote=/tmp/test_bes_git_repo_has_unpushed_changes_remote_$$
  local _tmp_remote_repo=${_tmp_remote}/repo
  mkdir -p ${_tmp_remote_repo}
  ( cd ${_tmp_remote_repo} && git init --bare --shared ) >& /dev/null
  local _tmp_local=/tmp/test_bes_git_repo_has_unpushed_changes_local_$$
  local _tmp_local_repo=${_tmp_local}/repo
  mkdir -p ${_tmp_local}
  ( cd ${_tmp_local} && git clone ${_tmp_remote_repo} repo ) >& /dev/null
  ( cd ${_tmp_local_repo} && echo "foo.txt" > foo.txt && git add foo.txt && git commit -mtest1 foo.txt && git push origin master ) >& /dev/null
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_unpushed_changes ${_tmp_local_repo} ) == 1 ]]"
  ( cd ${_tmp_local_repo} && echo "2foo.txt" > foo.txt && git commit -mtest2 foo.txt ) >& /dev/null  
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_unpushed_changes ${_tmp_local_repo} ) == 0 ]]"
  rm -rf ${_tmp_remote}
  rm -rf ${_tmp_local}
}

function test_bes_git_has_local_branch()
{
  local _tmp=$(bes_git_make_temp_repo git_has_local_branch)
  local _tmp_repo=${_tmp}/local
  bes_assert "[[ $(bes_testing_call_function bes_git_has_local_branch ${_tmp_repo} foo ) == 1 ]]"
  bes_git_call ${_tmp_repo} branch foo >& /dev/null
  bes_assert "[[ $(bes_testing_call_function bes_git_has_local_branch ${_tmp_repo} foo ) == 0 ]]"
}

bes_testing_run_unit_tests
