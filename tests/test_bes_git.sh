#!/bin/bash

function _test_bes_git_this_dir()
{
  local _this_file
  local _test_bes_git_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_git_this_dir="${_this_file%/*}"
  if [ "${_test_bes_git_this_dir}" == "${_this_file}" ]; then
    _test_bes_git_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_git_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source $(_test_bes_git_this_dir)/../bash/bes_shell/bes_shell.sh
source $(_test_bes_git_this_dir)/../bash/bes_shell/bes_git.sh

function test_bes_git_is_bare_repo_true()
{
  local _tmp=/tmp/test_bes_git_is_repo_true_$$
  mkdir -p ${_tmp}
  ( cd ${_tmp} && git init --bare --shared .  >& /dev/null )
  bes_assert "[[ $(bes_testing_call_function bes_git_is_bare_repo ${_tmp}) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_is_repo_true()
{
  local _tmp=/tmp/test_bes_git_is_repo_true_$$
  mkdir -p ${_tmp}
  ( cd ${_tmp} && git init .  >& /dev/null )
  bes_assert "[[ $(bes_testing_call_function bes_git_is_repo ${_tmp}) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_is_any_repo_bare_true()
{
  local _tmp=/tmp/test_bes_git_is_repo_true_$$
  mkdir -p ${_tmp}
  ( cd ${_tmp} && git init --bare --shared .  >& /dev/null )
  bes_assert "[[ $(bes_testing_call_function bes_git_is_any_repo ${_tmp}) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_is_any_repo_true()
{
  local _tmp=/tmp/test_bes_git_is_repo_true_$$
  mkdir -p ${_tmp}
  ( cd ${_tmp} && git init .  >& /dev/null )
  bes_assert "[[ $(bes_testing_call_function bes_git_is_any_repo ${_tmp}) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_is_repo_false()
{
  local _tmp=/tmp/test_bes_git_is_repo_false_$$
  mkdir -p ${_tmp}
  bes_assert "[[ $(bes_testing_call_function bes_git_is_repo ${_tmp}) == 1 ]]"
  rm -rf ${_tmp}
}

function xtest_bes_git_repo_has_uncommitted_changes()
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

function test_bes_git_local_branch_exists()
{
  local _tmp=$(bes_git_make_temp_repo git_local_branch_exists)
  local _tmp_repo=${_tmp}/local
  bes_assert "[[ $(bes_testing_call_function bes_git_local_branch_exists ${_tmp_repo} foo ) == 1 ]]"
  bes_git_call ${_tmp_repo} branch foo >& /dev/null
  bes_assert "[[ $(bes_testing_call_function bes_git_local_branch_exists ${_tmp_repo} foo ) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_local_branch_delete()
{
  local _tmp=$(bes_git_make_temp_repo git_local_branch_exists)
  local _tmp_repo=${_tmp}/local
  bes_git_call ${_tmp_repo} branch foo >& /dev/null
  bes_assert "[[ $(bes_testing_call_function bes_git_local_branch_exists ${_tmp_repo} foo ) == 0 ]]"
  bes_git_local_branch_delete ${_tmp_repo} foo >& /dev/null
  bes_assert "[[ $(bes_testing_call_function bes_git_local_branch_exists ${_tmp_repo} foo ) == 1 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_remote_is_added()
{
  local _tmp=$(bes_git_make_temp_repo bes_git_remote_is_added)
  local _tmp_repo=${_tmp}/local
  bes_assert "[[ $(bes_testing_call_function bes_git_remote_is_added ${_tmp_repo} foo ) == 1 ]]"
  bes_git_call ${_tmp_repo} remote add foo https://github.com/git/git.git >& /dev/null
  bes_assert "[[ $(bes_testing_call_function bes_git_remote_is_added ${_tmp_repo} foo ) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_remote_remove()
{
  local _tmp=$(bes_git_make_temp_repo bes_git_remote_is_added)
  local _tmp_repo=${_tmp}/local
  bes_git_call ${_tmp_repo} remote add foo https://github.com/git/git.git >& /dev/null
  bes_assert "[[ $(bes_testing_call_function bes_git_remote_is_added ${_tmp_repo} foo ) == 0 ]]"
  bes_git_remote_remove ${_tmp_repo} foo
  bes_assert "[[ $(bes_testing_call_function bes_git_remote_is_added ${_tmp_repo} foo ) == 1 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_last_commit_hash()
{
  local _tmp=$(bes_git_make_temp_repo bes_git_last_commit_hash)
  local _tmp_repo=${_tmp}/local
  local _commit_hash=$(bes_git_call ${_tmp_repo} log --format=%H -n 1)
  bes_assert "[[ $(bes_git_last_commit_hash ${_tmp_repo}) == ${_commit_hash} ]]"
  rm -rf ${_tmp}
}

function test_bes_git_last_commit_hash_short()
{
  local _tmp=$(bes_git_make_temp_repo bes_git_last_commit_hash)
  local _tmp_repo=${_tmp}/local
  local _commit_hash=$(bes_git_call ${_tmp_repo} log --format=%h -n 1)
  bes_assert "[[ $(bes_git_last_commit_hash ${_tmp_repo} true) == ${_commit_hash} ]]"
  rm -rf ${_tmp}
}

function _add_lfs_file()
{
  if [[ $# != 3 ]]; then
    bes_message "usage: _add_lfs_file repo filename content"
    return 1
  fi
  local _repo="${1}"
  local _filename="${2}"
  local _content="${3}"
  
  local _ext=$(bes_file_extension "${_filename}")
  ( cd ${_repo} && \
      git lfs install && \
      echo "*.${_ext} filter=lfs diff=lfs merge=lfs -text" > .gitattributes && \
      git add .gitattributes && \
      git commit -m"add attributes" .gitattributes && \
      echo "${_filename}" > "${_filename}" && \
      git add "${_filename}" && \
      git commit -m"add ${_filename}" "${_filename}"
  ) >& /dev/null
}

function test_bes_git_repo_has_lfs_files()
{
  local _temp_home=/tmp/test_bes_git_repo_has_lfs_files_temp_home_$$
  mkdir -p "${_temp_home}"
  local _save_home="${HOME}"
  export HOME="${_temp_home}"

  local _tmp=$(bes_git_make_temp_repo bes_git_repo_has_lfs_files)
  local _tmp_repo=${_tmp}/local
  local _commit_hash=$(bes_git_call ${_tmp_repo} log --format=%H -n 1)
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_lfs_files ${_tmp_repo} ) == 1 ]]"
  _add_lfs_file ${_tmp_repo} foo.bin "this is foo.bin"
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_lfs_files ${_tmp_repo} ) == 0 ]]"
  export HOME="${_save_home}"
  rm -rf "${_tmp}" "${_temp_home}"
}

function test_bes_git_submodule_revision()
{
  local _tmp=$(bes_git_make_temp_repo bes_git_submodule_revision)
  local _tmp_repo=${_tmp}/local

  local _tmp_sub=$(bes_git_make_temp_repo bes_git_submodule_revision_sub)
  local _tmp_sub_repo=${_tmp_sub}/local
  
  ( cd ${_tmp_sub_repo} && echo "insub.txt" > insub.txt && git add insub.txt && git commit -m"add" . ) >& /dev/null

  ( cd ${_tmp_repo} && git submodule add ${_tmp_sub_repo} addons/foo && git commit -m"add" . ) >& /dev/null

  local _sub_commit=$(bes_git_last_commit_hash ${_tmp_sub_repo})
  local _sub_commit_short=$(bes_git_last_commit_hash ${_tmp_sub_repo} true)

  bes_assert "[[ $(bes_git_submodule_revision ${_tmp_repo} addons/foo) == ${_sub_commit} ]]"
  bes_assert "[[ $(bes_git_submodule_revision ${_tmp_repo} addons/foo true) == ${_sub_commit_short} ]]"

  rm -rf "${_tmp}" "${_tmp_sub}"
}

function test_bes_git_submodule_revision_with_lfs()
{
  local _temp_home=/tmp/test_bes_git_submodule_with_lfs_temp_home_$$
  mkdir -p "${_temp_home}"
  local _save_home="${HOME}"
  export HOME="${_temp_home}"

  local _tmp=$(bes_git_make_temp_repo bes_git_submodule_with_lfs)
  local _tmp_repo=${_tmp}/local

  local _tmp_lfs_clone=$(_git_test_clone git@gitlab.com:rebuilder/lfs_test.git)

  local _sub_commit_long=$(bes_git_last_commit_hash ${_tmp_lfs_clone})
  local _sub_commit_short=$(bes_git_last_commit_hash ${_tmp_lfs_clone} true)

  ( cd ${_tmp_repo} && git submodule add git@gitlab.com:rebuilder/lfs_test.git sub/foo && git commit -m"add" . && git push ) >& /dev/null

  bes_assert "[[ $(bes_git_submodule_revision ${_tmp_repo} sub/foo) == ${_sub_commit_long} ]]"
  bes_assert "[[ $(bes_git_submodule_revision ${_tmp_repo} sub/foo true) == ${_sub_commit_short} ]]"

  export HOME="${_save_home}"

  rm -rf "${_tmp}" "${_tmp_lfs_clone}"
}

function _check_num_args()
{
  if [[ $# != 3 ]]; then
    bes_message "ERROR: _check_num_args got ${#} instead of 3 args."
    exit 1
  fi
  local _msg="${1}"
  local _expected="${2}"
  local _actual="${3}"
  if [[ ${_expected} != ${_actual} ]]; then
    bes_message "expecting ${_exepected} instead of ${_actual} num args: ${_msg}"
    exit 1
  fi
}  

function _git_test_address_name()
{
  _check_num_args "_git_test_address_name" 1 $#
  local _address=${1}
  local _name=$( echo ${_address}  | awk -F"/" '{ print $NF; }'  | sed 's/\.git//')
  echo ${_name}
  return 0
}

# Clone a repo to a tmp dir
function _git_test_clone()
{
  _check_num_args "_git_test_clone" 1 $#
  local _address=${1}
  local _name=$(_git_test_address_name ${_address})
  local _tmp=/tmp/temp_git_repo_${_name}_$$
  git clone ${_address} ${_tmp} >& /dev/null
  echo ${_tmp}
  return 0
}

bes_testing_run_unit_tests
