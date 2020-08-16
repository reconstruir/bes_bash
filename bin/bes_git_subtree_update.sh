#!/bin/bash

set -e

function main()
{
  source $(_this_dir)/../bash/bes_shell/bes_all.sh
  if [[ $# != 7 ]]; then
    bes_message "usage: local_branch address remote_branch revision src_dir dst_dir retry_with_delete"
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
  local _root="$(pwd)"
  local _tmp_branch_name=tmp-split-branch-${_remote_name}

  bes_message "updating ${_dst_dir} with ${_remote_address}/${_src_dir}@${_remote_revision}"

  if [[ ${_remote_revision} == "@latest@" ]]; then
    _remote_revision=$(bes_git_repo_latest_tag ${_remote_address})
    bes_message "using latest tag for ${_remote_address} is ${_remote_revision}"
  fi
  
  local _remote_commit_hash=$(_repo_ref_to_commit_hash ${_remote_address} ${_remote_revision})
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
  git pull origin ${_local_branch} >& /dev/null

  trap "_at_exit_cleanup ${_remote_name} ${_root} ${_tmp_branch_name}" EXIT

  if _do_subtree "${_root}" ${_local_branch} ${_remote_address} ${_remote_branch} ${_remote_revision} ${_remote_commit_hash} ${_src_dir} ${_dst_dir} ${_remote_name} ${_tmp_branch_name}; then
    bes_message "succeed without having to delete ${_dst_dir} first"
    return 0
  fi
  
  bes_message "subtree failed because of conflicts.  Hard resetting to the HEAD"

  git reset --hard HEAD

  if [[ ${_retry_with_delete} == "true" ]]; then
    bes_message "retrying with deleting ${_dst_dir} first"
    git rm -rf ${_dst_dir}
    git commit ${_dst_dir} -m"remove ${_dst_dir} so subtree can replace it without conflicts."
    if _do_subtree "${_root}" ${_local_branch} ${_remote_address} ${_remote_branch} ${_remote_revision} ${_remote_commit_hash} ${_src_dir} ${_dst_dir} ${_remote_name} ${_tmp_branch_name}; then
        bes_message "succeed with deleting ${_dst_dir} first"
        return 0
    fi
    bes_message "both subtree attempts failed.  something is very screwy"
  fi
  
  return 1
}

function _do_subtree()
{
  local _root=${1}
  local _local_branch=${2}
  local _remote_address=${3}
  local _remote_branch=${4}
  local _remote_revision=${5}
  local _remote_commit_hash=${6}
  local _src_dir=${7}
  local _dst_dir=${8}
  local _remote_name=${9}
  local _tmp_branch_name=${10}

  bes_git_remote_remove "${_root}" ${_remote_name}
  
  git checkout ${_local_branch} >& /dev/null
  git remote add -f ${_remote_name} ${_remote_address} -t ${_remote_branch} >& /dev/null # --no-tags
  bes_message "checking out ${_remote_name}/${_remote_branch}"
  git checkout ${_remote_name}/${_remote_branch} >& /dev/null
  bes_message "checking out ${_remote_commit_hash}"
  git checkout ${_remote_commit_hash} >& /dev/null
  bes_message "trying subtree split -P ${_src_dir} -b ${_tmp_branch_name}"
  git subtree split -P ${_src_dir} -b ${_tmp_branch_name} >& /dev/null
  bes_message "trying checkout ${_local_branch}"
  git checkout ${_local_branch} >& /dev/null

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
  if ! git subtree ${command} --squash -P ${_dst_dir} ${_tmp_branch_name} -m "${message}" >& /dev/null; then
    bes_message "FAILED: subtree subtree ${command} --squash -P ${_dst_dir}"
    _delete_tmp_branch "${_root}" ${_tmp_branch_name}
    return 1
  fi
  _delete_tmp_branch "${_root}" ${_tmp_branch_name}
  return 0
}

function _at_exit_cleanup()
{
  local _actual_exit_code=$?
  if [[ $# != 3 ]]; then
    bes_message "usage: _at_exit_cleanup remote_name root tmp_branch_name"
    return 1
  fi
  local _remote_name=${1}
  local _root=${2}
  local _tmp_branch_name=${3}
  bes_message "_at_exit_cleanup: _actual_exit_code=${_actual_exit_code} _remote_name=${_remote_name} _root=${_root} _root=${_tmp_branch_name}"
  bes_git_remote_remove "${_root}" ${_remote_name}
  _delete_tmp_branch "${_root}" ${_tmp_branch_name}
  if [[ ${_actual_exit_code} == 0 ]]; then
    bes_message "success"
  else
    bes_message "failed"
  fi
  return ${_actual_exit_code}
}

function _delete_tmp_branch()
{
  if [[ $# != 2 ]]; then
    bes_message "usage: _delete_tmp_branch root tmp_branch_name"
    return 1
  fi
  local _root=${1}
  local _tmp_branch_name=${2}
  if ! bes_git_local_branch_exists "${_root}" ${_tmp_branch_name}; then
    bes_message "no ${_tmp_branch_name} branch found to delete"
    return 0
  fi
  ( cd "${_root}" && git branch -D ${_tmp_branch_name} ) >& /dev/null
  bes_message "deleted ${_tmp_branch_name} branch"
  return 0
}

function _this_dir()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  return 0
}

function _repo_ref_to_commit_hash()
{
  if [[ $# != 2 ]]; then
    bes_message "usage: address ref"
    return 1
  fi
  local _address=${1}
  local _ref=${2}
  local _tmp=/tmp/git_subtree_update_repo_ref_to_commit_$$
  rm -rf "${_tmp}"
  mkdir -p "${_tmp}"
  git clone ${_address} "${_tmp}" >& /dev/null
  local _commit_hash=$(cd "${_tmp}" && git rev-list -n 1 ${_ref})
  rm -rf "${_tmp}"
  echo ${_commit_hash}
  return 0
}

main ${1+"$@"}
