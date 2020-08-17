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

  bes_git_subtree_update \
    "${_dst}" \
    master \
    ${_tmp_src_repo}/remote \
    master \
    master \
    "foo/bar" \
    "subtree" \
    false

  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/something/apple.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/kiwi.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/lemon.txt) == 0 ]]"
  
  rm -rf ${_tmp_src_repo} ${_tmp_dst_repo}
}

function test_bes_git_subtree_with_revision()
{
  local _tmp_src_repo=$(_bes_git_make_temp_repo test_bes_git_subtree_basic1)
  local _src=${_tmp_src_repo}/local

  local _tmp_dst_repo=$(_bes_git_make_temp_repo test_bes_git_subtree_basic2)
  local _dst=${_tmp_dst_repo}/local

  _bes_git_add_file "${_src}" "foo/bar/kiwi.txt" kiwi.txt true
  bes_git_tag "${_src}" "1.2.3"
  _bes_git_add_file "${_src}" "foo/bar/lemon.txt" lemon.txt true
  bes_git_tag "${_src}" "1.2.4"

  _bes_git_add_file "${_dst}" "something/apple.txt" apple.txt true

  bes_git_subtree_update \
    "${_dst}" \
    master \
    ${_tmp_src_repo}/remote \
    master \
    "1.2.3" \
    "foo/bar" \
    "subtree" \
    false
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/something/apple.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/kiwi.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/lemon.txt) == 1 ]]"
  
  rm -rf ${_tmp_src_repo} ${_tmp_dst_repo}
}

function test_bes_git_subtree_with_latest()
{
  local _tmp_src_repo=$(_bes_git_make_temp_repo test_bes_git_subtree_basic1)
  local _src=${_tmp_src_repo}/local

  local _tmp_dst_repo=$(_bes_git_make_temp_repo test_bes_git_subtree_basic2)
  local _dst=${_tmp_dst_repo}/local

  _bes_git_add_file "${_src}" "foo/bar/kiwi.txt" kiwi.txt true
  bes_git_tag "${_src}" "1.2.3"
  _bes_git_add_file "${_src}" "foo/bar/lemon.txt" lemon.txt true
  bes_git_tag "${_src}" "1.2.4"
  _bes_git_add_file "${_src}" "foo/bar/watermelon.txt" watermelon.txt false

  _bes_git_add_file "${_dst}" "something/apple.txt" apple.txt true

  bes_git_subtree_update \
    "${_dst}" \
    master \
    ${_tmp_src_repo}/remote \
    master \
    "@latest@" \
    "foo/bar" \
    "subtree" \
    false
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/something/apple.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/kiwi.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/lemon.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/watermelon.txt) == 1 ]]"
  
  rm -rf ${_tmp_src_repo} ${_tmp_dst_repo}
}

function test_bes_git_subtree_no_change()
{
  local _tmp_src_repo=$(_bes_git_make_temp_repo test_bes_git_subtree_basic1)
  local _src=${_tmp_src_repo}/local

  local _tmp_dst_repo=$(_bes_git_make_temp_repo test_bes_git_subtree_basic2)
  local _dst=${_tmp_dst_repo}/local

  _bes_git_add_file "${_src}" "foo/bar/kiwi.txt" kiwi.txt true
  bes_git_tag "${_src}" "1.2.3"
  _bes_git_add_file "${_src}" "foo/bar/lemon.txt" lemon.txt true
  bes_git_tag "${_src}" "1.2.4"

  _bes_git_add_file "${_dst}" "something/apple.txt" apple.txt true
  
  bes_git_subtree_update \
    "${_dst}" \
    master \
    ${_tmp_src_repo}/remote \
    master \
    "@latest@" \
    "foo/bar" \
    "subtree" \
    false
  
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/something/apple.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/kiwi.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/lemon.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/watermelon.txt) == 1 ]]"

  bes_git_subtree_update \
    "${_dst}" \
    master \
    ${_tmp_src_repo}/remote \
    master \
    "@latest@" \
    "foo/bar" \
    "subtree" \
    true
  
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/something/apple.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/kiwi.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/lemon.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/watermelon.txt) == 1 ]]"
  
  rm -rf ${_tmp_src_repo} ${_tmp_dst_repo}
}

function test_bes_git_subtree_conflicts()
{
  local _tmp_src_repo=$(_bes_git_make_temp_repo test_bes_git_subtree_basic1)
  local _src=${_tmp_src_repo}/local

  local _tmp_dst_repo=$(_bes_git_make_temp_repo test_bes_git_subtree_basic2)
  local _dst=${_tmp_dst_repo}/local

  _bes_git_add_file "${_src}" "foo/bar/kiwi.txt" kiwi.txt true
  bes_git_tag "${_src}" "1.2.3"
  _bes_git_add_file "${_src}" "foo/bar/lemon.txt" lemon.txt true
  bes_git_tag "${_src}" "1.2.4"

  _bes_git_add_file "${_dst}" "something/apple.txt" apple.txt true
  
  bes_git_subtree_update \
    "${_dst}" \
    master \
    ${_tmp_src_repo}/remote \
    master \
    "@latest@" \
    "foo/bar" \
    "subtree" \
    false
  
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/something/apple.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/kiwi.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/lemon.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/watermelon.txt) == 1 ]]"
  
  echo "this is hacked kiwi.txt" > "${_dst}/subtree/kiwi.txt"
  bes_git_call "${_dst}" commit -m"hacked" "subtree/kiwi.txt" >& ${_BES_GIT_LOG_FILE}

  _bes_git_add_file "${_src}" "foo/bar/watermelon.txt" watermelon.txt true
  bes_git_tag "${_src}" "1.2.5"
  
  bes_git_subtree_update \
    "${_dst}" \
    master \
    ${_tmp_src_repo}/remote \
    master \
    "@latest@" \
    "foo/bar" \
    "subtree" \
    true
  
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/something/apple.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/kiwi.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/lemon.txt) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function test -f ${_dst}/subtree/watermelon.txt) == 0 ]]"
  
  rm -rf ${_tmp_src_repo} ${_tmp_dst_repo}
}

bes_testing_run_unit_tests
