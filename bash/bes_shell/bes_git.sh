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
    return 1
  fi
  if bes_git_repo_has_uncommitted_changes ${_path}; then
    return 1
  fi
  if bes_git_repo_has_unpushed_changes ${_path}; then
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

_bes_trace_file "end"
