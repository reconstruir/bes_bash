#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

_bes_trace_file "begin"

# Return 0 if ${1} (or pwd if not given) is a bare git repo
function bes_git_is_bare_repo()
{
  if [[ $# -ge 1 ]]; then
    local _path="${1}"
  else
    local _path="$(pwd)"
  fi
  if [[ ! -f "${_path}"/HEAD ]]; then
    return 1
  fi
  if [[ ! -f "${_path}"/config ]]; then
    return 1
  fi
  if [[ ! -d "${_path}"/refs ]]; then
    return 1
  fi
  if [[ ! -d "${_path}"/objects ]]; then
    return 1
  fi
  return 0
}

# Return 0 if ${1} (or pwd if not given) is a git repo
function bes_git_is_repo()
{
  if [[ $# -ge 1 ]]; then
    local _path="${1}"
  else
    local _path="$(pwd)"
  fi
  if bes_git_is_bare_repo "${_path}"/.git; then
    return 0
  fi
  return 1
}

# Return 0 if ${1} (or pwd if not given) is either a working or bare git repo
function bes_git_is_any_repo()
{
  if [[ $# -ge 1 ]]; then
    local _path="${1}"
  else
    local _path="$(pwd)"
  fi
  if bes_git_is_repo "${_path}"; then
    return 0
  fi
  if bes_git_is_bare_repo "${_path}"; then
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
    local _path="$(pwd)"
  fi
  if ! bes_git_is_repo "${_path}"; then
    bes_message "not a git repo: ${_path}"
    return 1
  fi
  if bes_git_repo_has_uncommitted_changes "${_path}"; then
    bes_message "not clean - uncommitted changes: ${_path}"
    return 1
  fi
  if bes_git_repo_has_unpushed_changes "${_path}"; then
    bes_message "not clean - unpushed changes: ${_path}"
    return 1
  fi
  return 0
}

# Return 0 if git repo is clean with no uncommitted or unpushed changes.
function bes_git_non_bare_repo_is_clean()
{
  if [[ $# -ge 1 ]]; then
    local _path="${1}"
  else
    local _path="$(pwd)"
  fi
  if bes_git_is_bare_repo "${_path}"; then
    return 0
  fi
  if ! bes_git_is_repo "${_path}"; then
    bes_message "not a git repo: ${_path}"
    return 1
  fi
  if bes_git_repo_has_uncommitted_changes "${_path}"; then
    bes_message "not clean - uncommitted changes: ${_path}"
    return 1
  fi
  if bes_git_repo_has_unpushed_changes "${_path}"; then
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
    local _path="$(pwd)"
  fi

  if bes_git_is_bare_repo "${_path}"; then
    return 0
  fi

  if ! bes_git_is_repo "${_path}"; then
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
    local _path="$(pwd)"
  fi
  if ! bes_git_is_repo "${_path}"; then
    return 1
  fi
  local _cherries=$(cd "${_path}" && git cherry | grep -E '^\+\s[a-f0-9]+$' | wc -l)
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
  if bes_git_call "${_root}" branch | sed -E 's/^\*/ /' | awk '{ print $1; }' | grep -w ${_branch_name} >& /dev/null; then
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

# print the revision (commit hash) at which a submodule is pegged.
function bes_git_submodule_revision()
{
  if [[ $# != 1 ]]; then
    bes_message "usage: bes_git_submodule_revision submodule"
    return 1
  fi
  local _submodule=${1}
  local _revision=$(git submodule status ${_submodule} | sed -E 's/^\+//' | sed -E 's/^\-//' | awk '{ print $1; }')
  echo ${_revision}
  return 0
}

# update a submodule to the HEAD of its branch and commit the result with a meaningful message
function bes_git_submodule_update()
{
  if [[ $# != 1 ]]; then
    bes_message "usage: bes_git_submodule_update submodule"
    return 1
  fi
  
  if bes_git_repo_has_uncommitted_changes; then
    bes_message "bes_git_submodule_update: The git tree needs to be clean with no uncommitted changes."
    return 1
  fi
  local _submodule=${1}
  local _old_revision=$(bes_git_submodule_revision ${_submodule})
  git submodule update --init ${_submodule}
  git submodule update --remote --merge ${_submodule}
  local _new_revision=$(bes_git_submodule_revision ${_submodule})
  if [[ ${_old_revision} == ${_new_revision} ]]; then
    bes_message "submodule ${_submodule} already at latest revision ${_new_revision}"
    return 0
  fi
  local _message="submodule ${_submodule} updated from ${_old_revision} to ${_new_revision}"
  git commit -m"${_message}" .
  bes_message "${_message}"
  return 0
}

function bes_git_short_hash()
{
  if [[ $# != 1 ]]; then
    bes_message "usage: bes_git_short_hash long_hash"
    return 1
  fi
  local _long_hash=${1}
  local _short_hash=$(git rev-parse --short ${_long_hash})
  echo ${_short_hash}
  return 0
}

# return the commit hash to which the submodule points
function bes_git_submodule_commit()
{
  if [[ $# != 1 ]]; then
    bes_message "usage: bes_git_submodule_commit submodule"
    return 1
  fi
  local _submodule="${1}"
  local _commit_hash=$(git ls-tree HEAD "${_submodule}" | awk '$2 == "commit"' | awk '{ print $3; }')
  echo ${_commit_hash}
  return 0
}

function bes_git_pack_size()
{
  if [[ $# > 1 ]]; then
    bes_message "usage: bes_git_pack_size <root>"
    return 1
  fi
  local _root=
  if [[ $# == 1 ]]; then
    _root="${1}"
  else
    _root="$(pwd)"
  fi
  local _pack_size=$(cd "${_root}" && git count-objects -v | grep size-pack  | awk '{ print $2; }')
  echo ${_pack_size}
  return 0
}

# gc strategy published by bfg docs
function bes_git_gc()
{
  if [[ $# > 1 ]]; then
    bes_message "usage: bes_git_gc <repo>"
    return 1
  fi
  local _repo=
  if [[ $# == 1 ]]; then
    _repo="${1}"
  else
    _repo="$(pwd)"
  fi
  local _pack_size_before=$(bes_git_pack_size "${_repo}")
  local _gc_log="$(pwd)"/gc.log
  ( cd "${_repo}" && git reflog expire --expire=now --all && git gc --prune=now --aggressive >& ${_gc_log} )
  local _pack_size_after=$(bes_git_pack_size "${_repo}")
  bes_message "bes_git_gc: delta: before=${_pack_size_before} after=${_pack_size_after} gc_log=${_gc_log}"
  return 0
}

# gc strategy published by atlassian bitbucket
function bes_git_gc2()
{
  if [[ $# > 1 ]]; then
    bes_message "usage: bes_git_gc2 <repo>"
    return 1
  fi
  local _repo=
  if [[ $# == 1 ]]; then
    _repo="${1}"
  else
    _repo="$(pwd)"
  fi
  local _pack_size_before=$(bes_git_pack_size "${_repo}")
  local _gc_log="$(pwd)"/gc.log
  ( cd "${_repo}" && git \
      -c gc.auto=1 \
      -c gc.autodetach=false \
      -c gc.autopacklimit=1 \
      -c gc.garbageexpire=now \
      -c gc.reflogexpireunreachable=now \
      gc --prune=all >& ${_gc_log} )
  local _pack_size_after=$(bes_git_pack_size "${_repo}")
  bes_message "bes_git_gc: delta: before=${_pack_size_before} after=${_pack_size_after} gc_log=${_gc_log}"
  return 0
}

_bes_trace_file "end"
