#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

_bes_trace_file "begin"

function bes_git_subtree_graft()
{
  if [[ $# != 7 ]]; then
    bes_message "usage: bes_git_subtree_graft local_branch address remote_branch revision src_dir dst_dir retry_with_delete"
    return 2
  fi
  local _local_branch=${1}
  local _remote_address=${2}
  local _remote_branch=${3}
  local _remote_revision=${4}
  local _src_dir=${5}
  local _dst_dir=${6}
  local _retry_with_delete=${7}
  local _remote_name=$(basename ${_remote_address} | sed 's/.git//')
  local _root_dir="$(pwd)"
  local _tmp_branch_name=tmp-split-branch-${_remote_name}

  if ! bes_git_is_repo "${_root_dir}"; then
    bes_message "not a git repo: ${_root_dir}"
    return 1
  fi
  if bes_git_repo_has_uncommitted_changes "${_root_dir}"; then
    bes_message "not clean - uncommitted changes: ${_root_dir}"
    return 1
  fi
  
  bes_message "updating ${_dst_dir} with ${_remote_address}/${_src_dir}@${_remote_revision}"

  if [[ ${_remote_revision} == "@latest@" ]]; then
    _remote_revision=$(bes_git_repo_latest_tag ${_remote_address})
    bes_message "using latest tag for ${_remote_address} is ${_remote_revision}"
  fi
  
  local _remote_commit_hash=$(bes_git_repo_commit_for_ref ${_remote_address} ${_remote_revision})
  bes_message "using ${_remote_commit_hash} for ${_remote_revision}"
  
  local _current_branch=$(git branch | awk '{ print $2; }')
  if [[ ${_current_branch} != ${_local_branch} ]]; then
    if bes_git_repo_has_uncommitted_changes; then
      bes_message "The current branch is not ${_local_branch} and it has changes."
      return 1
    fi
    git checkout ${_local_branch}
  fi

  # We need a clean tree with no changes
  if bes_git_repo_has_uncommitted_changes; then
    bes_message "The git tree needs to be clean with no uncommitted changes."
    return 1
  fi

  bes_message "pulling origin ${_local_branch} to make sure up to date."
  git pull origin ${_local_branch} >& ${_BES_GIT_LOG_FILE}

  trap "_bes_subtree_at_exit_cleanup ${_remote_name} ${_root_dir} ${_tmp_branch_name}" EXIT

  if _bes_git_subtree_doit "${_root_dir}" ${_local_branch} ${_remote_address} ${_remote_branch} ${_remote_revision} ${_remote_commit_hash} ${_src_dir} ${_dst_dir} ${_remote_name} ${_tmp_branch_name}; then
    bes_message "succeed without having to delete ${_dst_dir} first"
    return 0
  fi
  
  bes_message "subtree failed because of conflicts.  Hard resetting to the HEAD"

  git reset --hard HEAD

  if [[ ${_retry_with_delete} == "true" ]]; then
    bes_message "retrying with deleting ${_dst_dir} first"
    git rm -rf ${_dst_dir}
    git commit ${_dst_dir} -m"remove ${_dst_dir} so subtree can replace it without conflicts."
    if _bes_git_subtree_doit "${_root_dir}" ${_local_branch} ${_remote_address} ${_remote_branch} ${_remote_revision} ${_remote_commit_hash} ${_src_dir} ${_dst_dir} ${_remote_name} ${_tmp_branch_name}; then
        bes_message "succeed with deleting ${_dst_dir} first"
        return 0
    fi
    bes_message "both subtree attempts failed.  something is very screwy"
  fi
  
  return 1
}

function _bes_git_subtree_doit()
{
  local _root_dir=${1}
  local _local_branch=${2}
  local _remote_address=${3}
  local _remote_branch=${4}
  local _remote_revision=${5}
  local _remote_commit_hash=${6}
  local _src_dir=${7}
  local _dst_dir=${8}
  local _remote_name=${9}
  local _tmp_branch_name=${10}

  bes_git_remote_remove "${_root_dir}" ${_remote_name}
  
  git checkout ${_local_branch} >& ${_BES_GIT_LOG_FILE}
  git remote add -f ${_remote_name} ${_remote_address} -t ${_remote_branch} >& ${_BES_GIT_LOG_FILE} # --no-tags
  bes_message "checking out ${_remote_name}/${_remote_branch}"
  git checkout ${_remote_name}/${_remote_branch} >& ${_BES_GIT_LOG_FILE}
  bes_message "checking out ${_remote_commit_hash}"
  git checkout ${_remote_commit_hash} >& ${_BES_GIT_LOG_FILE}
  bes_message "trying subtree split -P ${_src_dir} -b ${_tmp_branch_name}"
  git subtree split -P ${_src_dir} -b ${_tmp_branch_name} >& ${_BES_GIT_LOG_FILE}
  bes_message "trying checkout ${_local_branch}"
  git checkout ${_local_branch} >& ${_BES_GIT_LOG_FILE}

  if [[ -d ${_dst_dir} ]]; then
    # Merge existing subtree
    command="merge"
    message="Merging ${_remote_address} ${_remote_revision} ${_src_dir} into ${_dst_dir}"
  else
    # Add subtree for first time
    command="add"
    message="Adding ${_remote_address} ${_remote_revision} ${_src_dir} into ${_dst_dir}"
  fi

  bes_message "trying subtree subtree ${command} --squash -P ${_dst_dir}"
  if ! git subtree ${command} --squash -P ${_dst_dir} ${_tmp_branch_name} -m "${message}" >& ${_BES_GIT_LOG_FILE}; then
    bes_message "FAILED: subtree subtree ${command} --squash -P ${_dst_dir}"
    _bes_subtree_at_exit_delete_tmp_branch "${_root_dir}" ${_tmp_branch_name}
    return 1
  fi
  _bes_subtree_at_exit_delete_tmp_branch "${_root_dir}" ${_tmp_branch_name}
  return 0
}

function _bes_subtree_at_exit_cleanup()
{
  local _actual_exit_code=$?
  if [[ $# != 3 ]]; then
    bes_message "usage: _bes_subtree_at_exit_cleanup remote_name root tmp_branch_name"
    return 1
  fi
  local _remote_name=${1}
  local _root_dir=${2}
  local _tmp_branch_name=${3}
  bes_message "_bes_subtree_at_exit_cleanup: _actual_exit_code=${_actual_exit_code} _remote_name=${_remote_name} _root_dir=${_root_dir} _tmp_branch_name=${_tmp_branch_name}"
  bes_git_remote_remove "${_root_dir}" ${_remote_name}
  _bes_subtree_at_exit_delete_tmp_branch "${_root_dir}" ${_tmp_branch_name}
  if [[ ${_actual_exit_code} == 0 ]]; then
    bes_message "success"
  else
    bes_message "failed"
  fi
  return ${_actual_exit_code}
}

function _bes_subtree_at_exit_delete_tmp_branch()
{
  if [[ $# != 2 ]]; then
    bes_message "usage: _bes_subtree_at_exit_delete_tmp_branch root tmp_branch_name"
    return 1
  fi
  local _root_dir=${1}
  local _tmp_branch_name=${2}
  if ! bes_git_local_branch_exists "${_root_dir}" ${_tmp_branch_name}; then
    bes_message "no ${_tmp_branch_name} branch found to delete"
    return 0
  fi
  ( cd "${_root_dir}" && git branch -D ${_tmp_branch_name} ) >& ${_BES_GIT_LOG_FILE}
  bes_message "deleted ${_tmp_branch_name} branch"
  return 0
}

_bes_trace_file "end"
