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
  if $(cd "${_path}" && git diff-index --quiet HEAD --); then
    return 1
  fi
  return 0
}

# Return 0 if git repo has untracked files
function bes_git_repo_has_untracked_files()
{
  if [[ $# -ge 1 ]]; then
    local _path="${1}"
  else
    local _path="$(pwd)"
  fi

  if bes_git_is_bare_repo "${_path}"; then
    return 1
  fi

  if ! bes_git_is_repo "${_path}"; then
    return 1
  fi
  local _num=$(cd "${_path}" && git status --untracked=all --porcelain | grep "?? " | wc -l)
  if [[ $(expr ${_num}) > 0 ]]; then
    return 0
  fi
  return 1
}

# Return 0 if git repo has uncommited changes
function bes_git_repo_has_unpushed_changes()
{
  if [[ $# -ge 1 ]]; then
    local _repo="${1}"
  else
    local _repo="$(pwd)"
  fi
  if ! bes_git_is_repo "${_repo}"; then
    return 1
  fi
  local _cherries=$(bes_git_call "${_repo}" cherry | grep -E '^\+\s[a-f0-9]+$' | wc -l)
  if [[ ${_cherries} -ne 0 ]]; then
    return 0
  fi
  return 1
}

# Call git with a specific root
function bes_git_call()
{
  if [[ $# < 1 ]]; then
    echo "usage: bes_git_call repo <args>"
    return 1
  fi
  local _repo="${1}"
  shift
  ( cd "${_repo}" && git ${1+"$@"} )
  return $?
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
  if [[ $# < 1 ]]; then
    bes_message "usage: bes_git_last_commit_hash repo <short_hash>"
    return 1
  fi
  local _repo="${1}"
  local _long_hash=$(bes_git_call "${_repo}" log --format=%H -n 1)
  local _want_short_hash="false"
  if [[ $# > 1 ]]; then
    _want_short_hash=${2}
  fi
  if [[ ${_want_short_hash} == "true" ]]; then
    _hash=$(bes_git_short_hash "${_repo}" ${_long_hash})
  else
    _hash=${_long_hash}
  fi
  echo ${_hash}
  return 0
}  

# return the commit hash to which the submodule points
function bes_git_submodule_revision()
{
  if [[ $# < 2 ]]; then
    bes_message "usage: bes_git_submodule_commit repo submodule <short_hash>"
    return 1
  fi
  local _repo="${1}"
  local _submodule="${2}"
  local _want_short_hash="false"
  if [[ $# > 2 ]]; then
    _want_short_hash=${3}
  fi
  local _hash
  local _long_hash=$(bes_git_call "${_repo}" ls-tree HEAD "${_submodule}" | awk '$2 == "commit"' | awk '{ print $3; }')
  if [[ ${_want_short_hash} == "true" ]]; then
    _hash=$(bes_git_short_hash "${_repo}/${_submodule}" ${_long_hash})
  else
    _hash=${_long_hash}
  fi
  echo ${_hash}
  return 0
}

# init a submodule.  optional recursive argument
function bes_git_submodule_init()
{
  if [[ $# < 1 ]]; then
    bes_message "usage: bes_git_submodule_init submodule [recursive]"
    return 1
  fi
  
  if bes_git_repo_has_uncommitted_changes; then
    bes_message "bes_git_submodule_init: The git tree needs to be clean with no uncommitted changes."
    return 1
  fi
  local _submodule="${1}"
  local _recursive_flag=""
  if [[ $# > 1 ]]; then
    if [[ ${2} == "true" ]]; then
      _recursive_flag="--recursive"
    fi
  fi
  git submodule update --init ${_recursive_flag} "${_submodule}"
  return 0
}

# update a submodule to the given revision or HEAD if none is given
# commit the result with a meaningful message
# update is *NOT* recursive.  only the top level submodule is updated
function bes_git_submodule_update()
{
  if [[ $# < 2 ]]; then
    bes_message "usage: bes_git_submodule_update repo submodule [revision]"
    return 1
  fi
  local _repo="${1}"
  shift
  if bes_git_repo_has_uncommitted_changes "${_repo}"; then
    bes_message "bes_git_submodule_update: The git tree needs to be clean with no uncommitted changes: ${_repo}"
    return 1
  fi
  local _submodule=${1}
  shift
  local _revision="HEAD"
  if [[ $# > 0 ]]; then
    _revision=${1}
  fi
    
  local _old_revision=$(bes_git_submodule_revision "${_repo}" ${_submodule} true)
  ( cd "${_repo}" && git submodule update --init ${_submodule} )
  ( cd "${_repo}" && git submodule update --remote --merge ${_submodule} )
  local _new_revision=$(bes_git_last_commit_hash "${_repo}/${_submodule}" true)
  if [[ ${_old_revision} == ${_new_revision} ]]; then
    bes_message "submodule ${_submodule} already at latest revision ${_new_revision}"
    return 0
  fi
  ( cd "${_repo}" && git add ${1} )
  local _message="submodule ${_submodule} updated from ${_old_revision} to ${_new_revision}"
  ( cd "${_repo}" && git commit -m"${_message}" . )
  bes_message "${_message}"
  return 0
}

function bes_git_short_hash()
{
  if [[ $# != 2 ]]; then
    bes_message "usage: bes_git_short_hash repo long_hash"
    return 1
  fi
  local _repo="${1}"
  local _long_hash=${2}
  local _short_hash=$(bes_git_call "${_repo}" rev-parse --short ${_long_hash})
  echo ${_short_hash}
  return 0
}

function bes_git_pack_size()
{
  if [[ $# > 1 ]]; then
    bes_message "usage: bes_git_pack_size <repo>"
    return 1
  fi
  local _repo=
  if [[ $# == 1 ]]; then
    _repo="${1}"
  else
    _repo="$(pwd)"
  fi
  local _pack_size=$(bes_git_call "${_repo}" && git count-objects -v | grep size-pack  | awk '{ print $2; }')
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
  ( cd "${_repo}" && git reflog expire --expire=now --all && git gc --prune=now --aggressive ) >& ${_gc_log}
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
  bes_git_call "${_repo}" \
      -c gc.auto=1 \
      -c gc.autodetach=false \
      -c gc.autopacklimit=1 \
      -c gc.garbageexpire=now \
      -c gc.reflogexpireunreachable=now \
      gc --prune=all >& ${_gc_log}
  local _pack_size_after=$(bes_git_pack_size "${_repo}")
  bes_message "bes_git_gc: delta: before=${_pack_size_before} after=${_pack_size_after} gc_log=${_gc_log}"
  return 0
}

# Return true (1) if the repo has git lfs files
function bes_git_repo_has_lfs_files()
{
  local _repo=
  if [[ $# == 1 ]]; then
    _repo="${1}"
  else
    _repo="$(pwd)"
  fi
  local _n=$(bes_git_call "${_repo}" lfs ls-files | wc -l | awk '{ print $1; }')
  if [[ ${_n} != 0 ]]; then
    return 0
  fi
  return 1
}

_bes_trace_file "end"
