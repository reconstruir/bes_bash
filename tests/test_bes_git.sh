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
  echo $(command cd -P "${_test_bes_git_this_dir}" > ${_BES_GIT_LOG_FILE} && command pwd -P )
  return 0
}

source $(_test_bes_git_this_dir)/../bash/bes_shell/bes_shell.sh
source $(_test_bes_git_this_dir)/../bash/bes_shell/bes_git.sh
source $(_test_bes_git_this_dir)/../bash/bes_shell/bes_git_unit_test.sh

function test_bes_git_is_bare_repo_true()
{
  local _tmp=/tmp/test_bes_git_is_repo_true_$$
  mkdir -p ${_tmp}
  ( cd ${_tmp} && git init --bare --shared .  >& ${_BES_GIT_LOG_FILE} )
  bes_assert "[[ $(bes_testing_call_function bes_git_is_bare_repo ${_tmp}) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_is_repo_true()
{
  local _tmp=/tmp/test_bes_git_is_repo_true_$$
  mkdir -p ${_tmp}
  ( cd ${_tmp} && git init .  >& ${_BES_GIT_LOG_FILE} )
  bes_assert "[[ $(bes_testing_call_function bes_git_is_repo ${_tmp}) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_is_any_repo_bare_true()
{
  local _tmp=/tmp/test_bes_git_is_repo_true_$$
  mkdir -p ${_tmp}
  ( cd ${_tmp} && git init --bare --shared .  >& ${_BES_GIT_LOG_FILE} )
  bes_assert "[[ $(bes_testing_call_function bes_git_is_any_repo ${_tmp}) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_is_any_repo_true()
{
  local _tmp=/tmp/test_bes_git_is_repo_true_$$
  mkdir -p ${_tmp}
  ( cd ${_tmp} && git init . >& ${_BES_GIT_LOG_FILE} )
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

function test_bes_git_repo_has_uncommitted_changes()
{
  local _tmp=$(_bes_git_make_temp_repo git_repo_has_uncommitted_changes)
  local _tmp_repo=${_tmp}/local
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_uncommitted_changes ${_tmp_repo} ) == 1 ]]"
  ( cd "${_tmp_repo}" && echo "changed" > readme.txt )
  bes_git_repo_has_uncommitted_changes "${_tmp_repo}"
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_uncommitted_changes ${_tmp_repo} ) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_repo_has_uncommitted_changes_added_file()
{
  local _tmp=$(_bes_git_make_temp_repo git_repo_has_uncommitted_changes)
  local _tmp_repo=${_tmp}/local
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_uncommitted_changes ${_tmp_repo} ) == 1 ]]"
  ( cd "${_tmp_repo}" && echo "iamnew" > new_file.txt && git add -A )
  bes_git_repo_has_uncommitted_changes "${_tmp_repo}"
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_uncommitted_changes ${_tmp_repo} ) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_repo_has_unpushed_changes()
{
  local _tmp_remote=/tmp/test_bes_git_repo_has_unpushed_changes_remote_$$
  local _tmp_remote_repo=${_tmp_remote}/repo
  mkdir -p ${_tmp_remote_repo}
  ( cd ${_tmp_remote_repo} && git init --bare --shared ) >& ${_BES_GIT_LOG_FILE}
  local _tmp_local=/tmp/test_bes_git_repo_has_unpushed_changes_local_$$
  local _tmp_local_repo=${_tmp_local}/repo
  mkdir -p ${_tmp_local}
  ( cd ${_tmp_local} && git clone ${_tmp_remote_repo} repo ) >& ${_BES_GIT_LOG_FILE}
  _bes_git_add_file "${_tmp_local_repo}" "foo.txt" foo.txt true
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_unpushed_changes ${_tmp_local_repo} ) == 1 ]]"
  ( cd ${_tmp_local_repo} && echo "2foo.txt" > foo.txt && git commit -mtest2 foo.txt ) >& ${_BES_GIT_LOG_FILE}  
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_unpushed_changes ${_tmp_local_repo} ) == 0 ]]"
  rm -rf ${_tmp_remote}
  rm -rf ${_tmp_local}
}

function test_bes_git_repo_has_untracked_files()
{
  local _tmp=$(_bes_git_make_temp_repo git_repo_has_untracked_files)
  local _tmp_repo=${_tmp}/local
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_untracked_files ${_tmp_repo} ) == 1 ]]"
  ( cd "${_tmp_repo}" && echo "iamnew" > new_file.txt )
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_untracked_files ${_tmp_repo} ) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_local_branch_exists()
{
  local _tmp=$(_bes_git_make_temp_repo git_local_branch_exists)
  local _tmp_repo=${_tmp}/local
  bes_assert "[[ $(bes_testing_call_function bes_git_local_branch_exists ${_tmp_repo} foo ) == 1 ]]"
  bes_git_call ${_tmp_repo} branch foo >& ${_BES_GIT_LOG_FILE}
  bes_assert "[[ $(bes_testing_call_function bes_git_local_branch_exists ${_tmp_repo} foo ) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_local_branch_delete()
{
  local _tmp=$(_bes_git_make_temp_repo git_local_branch_exists)
  local _tmp_repo=${_tmp}/local
  bes_git_call ${_tmp_repo} branch foo >& ${_BES_GIT_LOG_FILE}
  bes_assert "[[ $(bes_testing_call_function bes_git_local_branch_exists ${_tmp_repo} foo ) == 0 ]]"
  bes_git_local_branch_delete ${_tmp_repo} foo >& ${_BES_GIT_LOG_FILE}
  bes_assert "[[ $(bes_testing_call_function bes_git_local_branch_exists ${_tmp_repo} foo ) == 1 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_remote_is_added()
{
  local _tmp=$(_bes_git_make_temp_repo bes_git_remote_is_added)
  local _tmp_repo=${_tmp}/local
  bes_assert "[[ $(bes_testing_call_function bes_git_remote_is_added ${_tmp_repo} foo ) == 1 ]]"
  bes_git_call ${_tmp_repo} remote add foo https://github.com/git/git.git >& ${_BES_GIT_LOG_FILE}
  bes_assert "[[ $(bes_testing_call_function bes_git_remote_is_added ${_tmp_repo} foo ) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_remote_remove()
{
  local _tmp=$(_bes_git_make_temp_repo bes_git_remote_is_added)
  local _tmp_repo=${_tmp}/local
  bes_git_call ${_tmp_repo} remote add foo https://github.com/git/git.git >& ${_BES_GIT_LOG_FILE}
  bes_assert "[[ $(bes_testing_call_function bes_git_remote_is_added ${_tmp_repo} foo ) == 0 ]]"
  bes_git_remote_remove ${_tmp_repo} foo
  bes_assert "[[ $(bes_testing_call_function bes_git_remote_is_added ${_tmp_repo} foo ) == 1 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_last_commit_hash()
{
  local _tmp=$(_bes_git_make_temp_repo bes_git_last_commit_hash)
  local _tmp_repo=${_tmp}/local
  local _commit_hash=$(bes_git_call ${_tmp_repo} log --format=%H -n 1)
  bes_assert "[[ $(bes_git_last_commit_hash ${_tmp_repo}) == ${_commit_hash} ]]"
  rm -rf ${_tmp}
}

function test_bes_git_last_commit_hash_short()
{
  local _tmp=$(_bes_git_make_temp_repo bes_git_last_commit_hash)
  local _tmp_repo=${_tmp}/local
  local _commit_hash=$(bes_git_call ${_tmp_repo} log --format=%h -n 1)
  bes_assert "[[ $(bes_git_last_commit_hash ${_tmp_repo} true) == ${_commit_hash} ]]"
  rm -rf ${_tmp}
}

function test_bes_git_repo_has_lfs_files()
{
  local _temp_home=/tmp/test_bes_git_repo_has_lfs_files_temp_home_$$
  mkdir -p "${_temp_home}"
  local _save_home="${HOME}"
  export HOME="${_temp_home}"

  local _tmp=$(_bes_git_make_temp_repo bes_git_repo_has_lfs_files)
  local _tmp_repo=${_tmp}/local
  local _commit_hash=$(bes_git_call ${_tmp_repo} log --format=%H -n 1)
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_lfs_files ${_tmp_repo} ) == 1 ]]"
  _bes_git_add_lfs_file ${_tmp_repo} foo.bin "this is foo.bin"
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_lfs_files ${_tmp_repo} ) == 0 ]]"
  export HOME="${_save_home}"
  rm -rf "${_tmp}" "${_temp_home}"
}

function test_bes_git_submodule_revision()
{
  local _tmp=$(_bes_git_make_temp_repo bes_git_submodule_revision)
  local _tmp_repo=${_tmp}/local

  local _tmp_sub=$(_bes_git_make_temp_repo bes_git_submodule_revision_sub)
  local _tmp_sub_repo=${_tmp_sub}/local
  
  _bes_git_add_file "${_tmp_sub_repo}" insub.txt "this is insub.txt\n" false

  ( cd ${_tmp_repo} && git submodule add ${_tmp_sub_repo} addons/foo && git commit -m"add" . ) >& ${_BES_GIT_LOG_FILE}

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

  local _tmp=$(_bes_git_make_temp_repo bes_git_submodule_with_lfs)
  local _tmp_repo=${_tmp}/local

  local _tmp_lfs_clone=$(_bes_git_test_clone git@gitlab.com:rebuilder/lfs_test.git)

  local _sub_commit_long=$(bes_git_last_commit_hash ${_tmp_lfs_clone})
  local _sub_commit_short=$(bes_git_last_commit_hash ${_tmp_lfs_clone} true)

  ( cd ${_tmp_repo} && git submodule add git@gitlab.com:rebuilder/lfs_test.git sub/foo && git commit -m"add" . && git push ) >& ${_BES_GIT_LOG_FILE}

  bes_assert "[[ $(bes_git_submodule_revision ${_tmp_repo} sub/foo) == ${_sub_commit_long} ]]"
  bes_assert "[[ $(bes_git_submodule_revision ${_tmp_repo} sub/foo true) == ${_sub_commit_short} ]]"

  export HOME="${_save_home}"

  rm -rf "${_tmp}" "${_tmp_lfs_clone}" "${_temp_home}"
}

function test_bes_git_submodule_update_no_revision()
{
  local _tmp=$(_bes_git_make_temp_repo bes_git_submodule_update)
  local _tmp_repo=${_tmp}/local

  local _tmp_sub=$(_bes_git_make_temp_repo bes_git_submodule_update_sub)
  local _tmp_sub_repo=${_tmp_sub}/local

  _bes_git_add_file "${_tmp_sub_repo}" insub.txt "this is insub.txt\n" true
  ( cd ${_tmp_repo} && git submodule add ${_tmp_sub_repo} addons/foo && git commit -m"add" . && git push ) >& ${_BES_GIT_LOG_FILE}

  local _sub_commit=$(bes_git_last_commit_hash ${_tmp_sub_repo})

  bes_assert "[[ $(bes_git_submodule_revision ${_tmp_repo} addons/foo) == ${_sub_commit} ]]"

  ( cd ${_tmp_sub_repo} && echo "insub2.txt" > insub.txt && git commit -m"update" .  && git push ) >& ${_BES_GIT_LOG_FILE}

  local _new_sub_commit=$(bes_git_last_commit_hash ${_tmp_sub_repo})
  bes_git_submodule_update "${_tmp_repo}" addons/foo >& ${_BES_GIT_LOG_FILE}

  bes_assert "[[ $(bes_git_submodule_revision ${_tmp_repo} addons/foo) == ${_new_sub_commit} ]]"

  rm -rf "${_tmp}" "${_tmp_sub}"
}

function test_custom_git_exe()
{
  local _tmp=$(_bes_git_make_temp_repo test_custom_git_exe_success)
  local _tmp_repo=${_tmp}/local
  local _fake_git=${_tmp}/fake_git.sh
  local _fake_git_breadcrumb=${_tmp}/breadcrumb.txt
  cat > ${_fake_git} << EOF
#!/bin/bash
echo foo > ${_fake_git_breadcrumb}
exec git \${1+"\$@"}
EOF
  chmod 755 ${_fake_git}
  export BES_GIT_EXE=${_fake_git}
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_uncommitted_changes ${_tmp_repo} ) == 1 ]]"
  ( cd "${_tmp_repo}" && echo "changed" > readme.txt )
  bes_git_repo_has_uncommitted_changes "${_tmp_repo}"
  bes_assert "[[ $(bes_testing_call_function bes_git_repo_has_uncommitted_changes ${_tmp_repo} ) == 0 ]]"
  bes_assert "[[ $(cat ${_fake_git_breadcrumb} ) == foo ]]"
  rm -rf ${_tmp}
}

function test_bes_git_tag()
{
  local _tmp=$(_bes_git_make_temp_repo test_bes_git_tag)
  local _tmp_repo=${_tmp}/local
  _bes_git_add_file "${_tmp_repo}" "foo.txt" foo.txt true
  bes_git_tag "${_tmp_repo}" "1.2.3"
  bes_assert "[[ $(bes_git_greatest_remote_tag ${_tmp_repo} ) == 1.2.3 ]]"
  _bes_git_add_file "${_tmp_repo}" "bar.txt" bar.txt true
  bes_assert "[[ $(bes_git_greatest_remote_tag ${_tmp_repo} ) == 1.2.3 ]]"
  bes_git_tag "${_tmp_repo}" "1.2.4"
  bes_assert "[[ $(bes_git_greatest_remote_tag ${_tmp_repo} ) == 1.2.4 ]]"
  bes_assert "[[ $(bes_git_list_remote_tags ${_tmp_repo} | tr \\n _ ) == 1.2.3_1.2.4_ ]]"
  bes_assert "[[ $(bes_testing_call_function bes_git_has_remote_tag ${_tmp_repo} 1.2.3 ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_git_has_remote_tag ${_tmp_repo} 1.2.4 ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_git_has_remote_tag ${_tmp_repo} 1.2.5 ) == 1 ]]"
  rm -rf ${_tmp}
}

function test_bes_git_list_remote_prefixed_tags()
{
  local _tmp=$(_bes_git_make_temp_repo bes_git_list_remote_prefixed_tags)
  local _tmp_repo=${_tmp}/local
  _bes_git_add_file "${_tmp_repo}" "kiwi.txt" kiwi.txt true
  bes_git_tag "${_tmp_repo}" "rel/fruit/1.2.3"
  _bes_git_add_file "${_tmp_repo}" "apple.txt" apple.txt true
  bes_git_tag "${_tmp_repo}" "rel/fruit/1.2.4"
  _bes_git_add_file "${_tmp_repo}" "brie.txt" brie.txt true
  bes_git_tag "${_tmp_repo}" "rel/cheese/1.0.0"
  bes_assert "[[ $(bes_git_list_remote_tags ${_tmp_repo} | tr \\n _ ) == rel/cheese/1.0.0_rel/fruit/1.2.3_rel/fruit/1.2.4_ ]]"
  
  bes_assert "[[ $(bes_git_list_remote_prefixed_tags ${_tmp_repo} rel/fruit | tr \\n _ ) == rel/fruit/1.2.3_rel/fruit/1.2.4_ ]]"
  bes_assert "[[ $(bes_git_list_remote_prefixed_tags ${_tmp_repo} rel/cheese | tr \\n _ ) == rel/cheese/1.0.0_ ]]"
  bes_assert "[[ $(bes_git_list_remote_prefixed_tags ${_tmp_repo} rel/wine | tr \\n _ ) == ]]"
  rm -rf ${_tmp}
}

function test_bes_git_greatest_remote_prefixed_tag()
{
  local _tmp=$(_bes_git_make_temp_repo bes_git_greatest_remote_prefixed_tag)
  local _tmp_repo=${_tmp}/local
  _bes_git_add_file "${_tmp_repo}" "kiwi.txt" kiwi.txt true
  bes_git_tag "${_tmp_repo}" "rel/fruit/1.2.3"
  _bes_git_add_file "${_tmp_repo}" "apple.txt" apple.txt true
  bes_git_tag "${_tmp_repo}" "rel/fruit/1.2.4"
  _bes_git_add_file "${_tmp_repo}" "brie.txt" brie.txt true
  bes_git_tag "${_tmp_repo}" "rel/cheese/1.0.0"

  bes_assert "[[ $(bes_git_greatest_remote_prefixed_tag ${_tmp_repo} rel/fruit/ ) == rel/fruit/1.2.4 ]]"
  bes_assert "[[ $(bes_git_greatest_remote_prefixed_tag ${_tmp_repo} rel/cheese/ ) == rel/cheese/1.0.0 ]]"
  bes_assert "[[ $(bes_git_greatest_remote_prefixed_tag ${_tmp_repo} rel/wine/ ) ==  ]]"
  rm -rf ${_tmp}
}

function test_bes_git_commit_for_ref()
{
  local _tmp=$(_bes_git_make_temp_repo bes_git_commit_for_ref)
  local _tmp_repo=${_tmp}/local
  _bes_git_add_file "${_tmp_repo}" "kiwi.txt" kiwi.txt true
  bes_git_tag "${_tmp_repo}" "rel/fruit/1.2.3"
  local _commit_hash=$(bes_git_call ${_tmp_repo} rev-list -n 1 rel/fruit/1.2.3)
  bes_assert "[[ $(bes_git_commit_for_ref ${_tmp_repo} rel/fruit/1.2.3) == ${_commit_hash} ]]"
  rm -rf ${_tmp}
}

function test_bes_git_commit_for_ref_short()
{
  local _tmp=$(_bes_git_make_temp_repo bes_git_commit_for_ref)
  local _tmp_repo=${_tmp}/local
  _bes_git_add_file "${_tmp_repo}" "kiwi.txt" kiwi.txt true
  bes_git_tag "${_tmp_repo}" "rel/fruit/1.2.3"
  local _commit_hash=$(bes_git_call ${_tmp_repo} rev-list -n 1 rel/fruit/1.2.3)
  bes_assert "[[ $(bes_git_commit_for_ref ${_tmp_repo} rel/fruit/1.2.3 true) == ${_commit_hash} ]]"
  rm -rf ${_tmp}
}

function test_bes_git_repo_commit_for_ref()
{
  local _tmp=$(_bes_git_make_temp_repo test_bes_git_repo_commit_for_ref)
  local _tmp_repo=${_tmp}/local

  _bes_git_add_file "${_tmp_repo}" "kiwi.txt" kiwi.txt true
  bes_git_tag "${_tmp_repo}" "rel/fruit/1.2.3"
  local _commit_hash_kiwi=$(bes_git_call ${_tmp_repo} rev-list -n 1 rel/fruit/1.2.3)

  _bes_git_add_file "${_tmp_repo}" "apple.txt" apple.txt true
  bes_git_tag "${_tmp_repo}" "rel/fruit/1.2.4"
  local _commit_hash_apple=$(bes_git_call ${_tmp_repo} rev-list -n 1 rel/fruit/1.2.4)

  bes_assert "[[ $(bes_git_repo_commit_for_ref ${_tmp}/remote rel/fruit/1.2.3) == ${_commit_hash_kiwi} ]]"
  bes_assert "[[ $(bes_git_repo_commit_for_ref ${_tmp}/remote rel/fruit/1.2.4) == ${_commit_hash_apple} ]]"
  rm -rf ${_tmp}
}

function test_bes_git_repo_latest_tag()
{
  local _tmp=$(_bes_git_make_temp_repo test_bes_git_repo_latest_tag)
  local _tmp_repo=${_tmp}/local

  _bes_git_add_file "${_tmp_repo}" "kiwi.txt" kiwi.txt true
  bes_git_tag "${_tmp_repo}" "1.0.0"
  bes_assert "[[ $(bes_git_repo_latest_tag ${_tmp}/remote) == 1.0.0 ]]"

  _bes_git_add_file "${_tmp_repo}" "apple.txt" apple.txt true
  bes_git_tag "${_tmp_repo}" "1.0.1"
  bes_assert "[[ $(bes_git_repo_latest_tag ${_tmp}/remote) == 1.0.1 ]]"
  
  rm -rf ${_tmp}
}

function test_bes_git_commit_message()
{
  local _tmp=$(_bes_git_make_temp_repo test_bes_git_commit_message)
  local _tmp_repo=${_tmp}/local

  _bes_git_add_file "${_tmp_repo}" "kiwi.txt" kiwi.txt true
  bes_git_tag "${_tmp_repo}" "rel/fruit/1.2.3"
  local _commit_hash_kiwi=$(bes_git_call ${_tmp_repo} rev-list -n 1 rel/fruit/1.2.3)
  local _kiwi_message=$(bes_git_commit_message ${_tmp_repo} ${_commit_hash_kiwi} | tr ' ' '_')
  bes_assert "[[ ${_kiwi_message} == add_kiwi.txt ]]"

  _bes_git_add_file "${_tmp_repo}" "apple.txt" apple.txt true
  bes_git_tag "${_tmp_repo}" "rel/fruit/1.2.4"
  local _commit_hash_apple=$(bes_git_call ${_tmp_repo} rev-list -n 1 rel/fruit/1.2.4)
  local _apple_message=$(bes_git_commit_message ${_tmp_repo} ${_commit_hash_apple} | tr ' ' '_')
  bes_assert "[[ ${_apple_message} == add_apple.txt ]]"
  
  rm -rf ${_tmp}
}

bes_testing_run_unit_tests
