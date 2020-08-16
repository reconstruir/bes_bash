#!/bin/bash

set -e

function main()
{
  source $(_this_dir)/../bash/bes_shell/bes_all.sh

  if [[ $# < 3 ]]; then
    bes_message "usage: address src_dir dst_dir <tag>"
    return 1
  fi
  local _address=${1}
  shift
  local _src_dir=${1}
  shift
  local _dst_dir=${1}
  shift
  local _tag="@latest@"
  if [[ $# > 0 ]]; then
    _tag=${1}
  fi

  if [[ ${_tag} == "@latest@" ]]; then
    _tag=$(bes_git_repo_latest_tag ${_address})
  fi

  bes_message "_address=${_address} _src_dir=${_src_dir} _dst_dir=${_dst_dir} _tag=${_tag}"
  $(_this_dir)/../bin/bes_git_subtree_update.sh \
    master \
    ${_address} \
    master \
    ${_tag} \
    "${_src_dir}" \
    "${_dst_dir}" \
    true

  return 0
}

function _this_dir()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  return 0
}

main ${1+"$@"}
