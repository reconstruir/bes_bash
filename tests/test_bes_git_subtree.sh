#!/bin/bash

function _test_bes_git_subtree_this_dir()
{
  local _this_file
  local _test_bes_git_subtree_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_git_subtree_this_dir="${_this_file%/*}"
  if [ "${_test_bes_git_subtree_this_dir}" == "${_this_file}" ]; then
    _test_bes_git_subtree_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_git_subtree_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source $(_test_bes_git_subtree_this_dir)/../bash/bes_shell/bes_shell.sh
source $(_test_bes_git_subtree_this_dir)/../bash/bes_shell/bes_git.sh
source $(_test_bes_git_subtree_this_dir)/../bash/bes_shell/bes_git_subtree.sh
source $(_test_bes_git_subtree_this_dir)/../bash/bes_shell/bes_git_unit_test.sh

function test_bes_git_subtree_basic()
{
  local _tmp_repo1=$(_bes_git_make_temp_repo test_bes_git_subtree_basic1)
  local _r1=${_tmp_repo1}/local

  local _tmp_repo2=$(_bes_git_make_temp_repo test_bes_git_subtree_basic2)
  local _r2=${_tmp_repo2}/local

  _bes_git_add_file "${_r1}" "foo/bar/kiwi.txt" kiwi.txt true
  bes_git_tag "${_r1}" "1.2.3"

  #local _commit_hash_kiwi=$(bes_git_call ${_tmp_repo} rev-list -n 1 rel/fruit/1.2.3)
  #local _kiwi_message=$(bes_git_commit_message ${_tmp_repo} ${_commit_hash_kiwi} | tr ' ' '_')
  #bes_assert "[[ ${_kiwi_message} == add_kiwi.txt ]]"

  #_bes_git_add_file "${_tmp_repo}" "apple.txt" apple.txt true
  #bes_git_tag "${_tmp_repo}" "rel/fruit/1.2.4"
  #local _commit_hash_apple=$(bes_git_call ${_tmp_repo} rev-list -n 1 rel/fruit/1.2.4)
  #local _apple_message=$(bes_git_commit_message ${_tmp_repo} ${_commit_hash_apple} | tr ' ' '_')
  #bes_assert "[[ ${_apple_message} == add_apple.txt ]]"
  
  rm -rf ${_tmp_repo1} ${_tmp_repo2}
}

bes_testing_run_unit_tests
