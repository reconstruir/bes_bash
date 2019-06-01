#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

_bes_trace_file "begin"

# Return 0 if ${1} (or pwd if not given) is a git repo
function bes_git_is_repo()
{
  if [[ $# -ge 1 ]]; then
    local _path="${1}"
  else
    local _path=$(pwd)
  fi
  if [[ -d ${_path}/.git ]]; then
    return 0
  fi
  return 1
}

# Return 0 if git repo is clean with no uncommitted or unpushed changes.
function bes_git_repo_is_clean()
{
  if [[ $# -ge 1 ]]; then
    local _path="${1}"
  else
    local _path=$(pwd)
  fi
  if ! bes_git_is_repo ${_path}; then
    bes_message "not a git repo: ${_path}"
    return 1
  fi
  if bes_git_repo_has_uncommitted_changes ${_path}; then
    bes_message "not clean - uncommitted changes: ${_path}"
    return 1
  fi
  if bes_git_repo_has_unpushed_changes ${_path}; then
    bes_message "not clean - unpushed changes: ${_path}"
    return 1
  fi
  return 0
}

# Return 0 if git repo has uncommited changes
function bes_git_repo_has_uncommitted_changes()
{
  if [[ $# -ge 1 ]]; then
    local _path="${1}"
  else
    local _path=$(pwd)
  fi
  if ! bes_git_is_repo ${_path}; then
    return 1
  fi
  local _diff=$(git diff)
  if [[ -n "${_diff}" ]]; then
    return 0
  fi
  return 1
}

# Return 0 if git repo has uncommited changes
function bes_git_repo_has_unpushed_changes()
{
  if [[ $# -ge 1 ]]; then
    local _path="${1}"
  else
    local _path=$(pwd)
  fi
  if ! bes_git_is_repo ${_path}; then
    return 1
  fi
  local _cherries=$(cd ${_path} && git cherry | grep -E '^\+\s[a-f0-9]+$' | wc -l)
  if [[ ${_cherries} -ne 0 ]]; then
    return 0
  fi
  return 1
}

# Call git with a specific root
function bes_git_call()
{
  if [[ $# < 1 ]]; then
    echo "usage: bes_git_call root <args>"
    return 1
  fi
  local _root="${1}"
  shift
  git --git-dir "${_root}/.git" --work-tree "${_root}" ${1+"$@"}
  return $?
}

function bes_git_add_file()
{
  if [[ $# != 3 ]]; then
    echo "usage: bes_git_add_file root filename content"
    return 1
  fi
  local _root="${1}"
  local _filename="${2}"
  local _content="${3}"
  local _dirname=$(dirname "${_filename}")
  ( cd ${_root} && mkdir -p ${_dirname} && echo "${_content}" > ${_filename} && git add ${_filename} && git commit -m"add ${_filename}" ${_filename} && git push origin master ) >& /dev/null
  return 0
}

function bes_git_make_temp_repo()
{
  if [[ $# != 1 ]]; then
    echo "usage: bes_git_make_temp_repo name"
    return 1
  fi
  local _name="${1}"
  local _tmp=/tmp/temp_git_repo_${_name}_$$
  local _tmp_remote_repo=${_tmp}/remote
  mkdir -p ${_tmp_remote_repo}
  ( cd ${_tmp_remote_repo} && git init --bare --shared ) >& /dev/null
  local _tmp_local_repo=${_tmp}/local
  ( cd ${_tmp} && git clone ${_tmp_remote_repo} local ) >& /dev/null
  bes_git_add_file ${_tmp_local_repo} readme.txt "this is readme.txt\n" 
  echo ${_tmp}
  return 0
}

function bes_git_local_branch_exists()
{
  if [[ $# != 2 ]]; then
    echo "usage: bes_git_local_branch_exists root branch_name"
    return 1
  fi
  local _root="${1}"
  local _branch_name="${2}"
  if bes_git_call "${_root}" branch | sed -r 's/^\*/ /' | awk '{ print $1; }' | grep -w ${_branch_name} >& /dev/null; then
    return 0
  fi
  return 1
}

function bes_git_local_branch_delete()
{
  if [[ $# != 2 ]]; then
    echo "usage: bes_git_local_branch_delete root branch_name"
    return 1
  fi
  local _root="${1}"
  local _branch_name="${2}"
  if bes_git_local_branch_exists "${_root}" ${_branch_name}; then
    bes_git_call "${_root}" branch --delete ${_branch_name}
  fi
  return 0
}

function bes_git_remote_is_added()
{
  if [[ $# != 2 ]]; then
    bes_message "usage: bes_git_remote_is_added root remote_name"
    return 1
  fi
  local _root="${1}"
  local _remote_name=${2}
  if bes_git_call "${_root}" ls-remote --exit-code ${_remote_name} >& /dev/null; then
    return 0
  fi
  return 1
}

function bes_git_remote_remove()
{
  if [[ $# != 2 ]]; then
    bes_message "usage: bes_git_has_remote root remote_name"
    return 1
  fi
  local _root="${1}"
  local _remote_name=${2}
  if bes_git_remote_is_added "${_root}" ${_remote_name}; then
    bes_git_call "${_root}" remote remove ${_remote_name}
  fi
  return 0
}  

function bes_git_last_commit_hash()
{
  if [[ $# > 1 ]]; then
    bes_message "usage: bes_git_last_commit_hash <root>"
    return 1
  fi
  local _root=
  
  if [[ $# == 1 ]]; then
    _root="${1}"
  else
    _root="$(pwd)"
  fi
  bes_git_call "${_root}" log --format=%H -n 1
  return 0
}  

_bes_trace_file "end"
