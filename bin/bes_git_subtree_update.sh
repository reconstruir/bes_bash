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

  bes_git_subtree_graft ${_local_branch} ${_address} ${_remote_branch} ${_remote_revision} ${_src_dir} ${_dst_dir} ${_retry_with_delete}
  local _rv=$?
  return ${_rv}
}

function _this_dir()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  return 0
}

main ${1+"$@"}
