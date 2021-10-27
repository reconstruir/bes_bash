#!/bin/bash

set -e

function main()
{
  source $(_bes_bash_update_this_dir)/../bash/bes_bash/bes_all.sh

  local _root_dir="$(pwd)"
  local _local_branch="master"
  local _address="git@gitlab_rebuilder:rebuilder/bes_bash.git"
  local _remote_branch="master"
  local _revision="@latest@"
  local _src_dir="bash/bes_bash"
  local _dst_dir="bes_bash"
  local _retry_with_delete="true"

  bes_git_subtree_update \
    ${_root_dir} \
    ${_local_branch} \
    ${_address} \
    ${_remote_branch} \
    ${_revision} \
    "${_src_dir}" \
    "${_dst_dir}" \
    ${_retry_with_delete}
  
  return 0
}

function _bes_bash_update_this_dir()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  return 0
}

main ${1+"$@"}
