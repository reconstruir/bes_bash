#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

_bes_trace_file "begin"

function _bes_git_add_file()
{
  if [[ $# != 3 ]]; then
    echo "usage: _bes_git_add_file root filename content"
    return 1
  fi
  local _root="${1}"
  local _filename="${2}"
  local _content="${3}"
  local _dirname=$(dirname "${_filename}")
  ( cd ${_root} && mkdir -p ${_dirname} && echo "${_content}" > ${_filename} && git add ${_filename} && git commit -m"add ${_filename}" ${_filename} && git push origin master ) >& /dev/null
  return 0
}

function _bes_git_make_temp_repo()
{
  if [[ $# != 1 ]]; then
    echo "usage: bes_git_make_temp_repo name"
    return 1
  fi
  local _name="${1}"
  local _tmp=/tmp/temp_git_repo_${_name}_$$
  local _tmp_remote_repo=${_tmp}/remote
  mkdir -p ${_tmp_remote_repo}
  ( bes_git_call "${_tmp_remote_repo}" init --bare --shared ) >& /dev/null
  local _tmp_local_repo=${_tmp}/local
  ( bes_git_call "${_tmp}" clone ${_tmp_remote_repo} local ) >& /dev/null
  _bes_git_add_file ${_tmp_local_repo} readme.txt "this is readme.txt\n" 
  echo ${_tmp}
  return 0
}

function _bes_git_check_num_args()
{
  if [[ $# != 3 ]]; then
    bes_message "ERROR: _bes_git_check_num_args got ${#} instead of 3 args."
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

function _bes_git_test_address_name()
{
  _bes_git_check_num_args "_bes_git_test_address_name" 1 $#
  local _address=${1}
  local _name=$( echo ${_address}  | awk -F"/" '{ print $NF; }'  | sed 's/\.git//')
  echo ${_name}
  return 0
}

# Clone a repo to a tmp dir
function _bes_git_test_clone()
{
  _bes_git_check_num_args "_bes_git_test_clone" 1 $#
  local _address=${1}
  local _name=$(_bes_git_test_address_name ${_address})
  local _tmp=/tmp/temp_git_repo_${_name}_$$
  git clone ${_address} ${_tmp} >& /dev/null
  echo ${_tmp}
  return 0
}

_bes_trace_file "end"
