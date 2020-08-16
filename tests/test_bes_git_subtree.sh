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
  local _tmp_src_repo=$(_bes_git_make_temp_repo test_bes_git_subtree_basic1)
  local _src=${_tmp_src_repo}/local

  local _tmp_dst_repo=$(_bes_git_make_temp_repo test_bes_git_subtree_basic2)
  local _dst=${_tmp_dst_repo}/local

  _bes_git_add_file "${_src}" "foo/bar/kiwi.txt" kiwi.txt true
  _bes_git_add_file "${_src}" "foo/bar/lemon.txt" lemon.txt true
  bes_git_tag "${_src}" "1.2.3"

  _bes_git_add_file "${_dst}" "something/apple.txt" apple.txt true

  echo before
  bes_git_subtree_update \
    "${_dst}" \
    master \
    ${_tmp_src_repo}/remote \
    master \
    master \
    "foo/bar" \
    "subtree" \
    false
  echo after

  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/something/apple.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/kiwi.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/lemon.txt) == 0 ]]"
  
  rm -rf ${_tmp_src_repo} ${_tmp_dst_repo}
}

bes_testing_run_unit_tests
