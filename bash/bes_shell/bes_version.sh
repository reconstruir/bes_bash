#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

_bes_trace_file "begin"

# Return 0 if version is a valid software version in the form $major.$minor.$revision
function bes_version_is_valid()
{
  if [[ $# < 1 ]]; then
    bes_message "usage: bes_version_is_valid version"
    return 1
  fi
  local _version="${1}"
  local _pattern='^[0-9]+\.[0-9]+\.[0-9]+$'
  if [[ ${_version} =~ ${_pattern} ]]; then
    return 0
  fi
  return 1
}

# Return 0 if part is one of "major" "minor" or "revision"
function bes_version_part_name_is_valid()
{
  if [[ $# < 1 ]]; then
    bes_message "usage: bes_version_part_name_is_valid part"
    return 1
  fi
  local _part="${1}"
  case ${_part} in
    major|minor|revision)
      return 0
      ;;
	  *)
      ;;
	esac
  return 1
}

# Bump a version.  part is optional and should one of major minor or revision
function _bes_version_part_index_part()
{
  if [[ $# < 1 ]]; then
    bes_message "usage: _bes_version_part_index_part <part>"
    return 1
  fi
  local _part=${1}

  if ! bes_version_part_name_is_valid ${_part}; then
    bes_message "bes_version_get_part: invalid part: ${_part}"
    return 1
  fi

  local _index
  case ${_part} in
    major)
      _index=0
      ;;
    minor)
      _index=1
      ;;
    revision)
      _index=2
      ;;
	esac
  echo ${_index}
  return 0
  }
  
# get a version part
function bes_version_get_part()
{
  if [[ $# < 2 ]]; then
    bes_message "usage: bes_version_get_part version part"
    return 1
  fi
  local _version="${1}"
  local _part="${2}"

  if ! bes_version_is_valid ${_version}; then
    bes_message "bes_version_get_part: invalid version: ${_version}"
    return 1
  fi
  
  if ! bes_version_part_name_is_valid ${_part}; then
    bes_message "bes_version_get_part: invalid part: ${_part}"
    return 1
  fi

  local _parts=( $(bes_str_split ${_version} .) )
  local _index=$(_bes_version_part_index_part ${_part})
  echo ${_parts[${_index}]}
  return 0
}

# Bump a version.  part is optional and should one of major minor or revision
function bes_version_bump()
{
  if [[ $# < 1 ]]; then
    bes_message "usage: bes_version_bump version <part>"
    return 1
  fi
  local _version="${1}"
  local _part=revision
  shift
  if [[ $# > 0 ]]; then
    _part=${1}
  fi

  if ! bes_version_is_valid ${_version}; then
    bes_message "bes_version_bump: invalid version: ${_version}"
    return 1
  fi
  
  if ! bes_version_part_name_is_valid ${_part}; then
    bes_message "bes_version_bump: invalid part: ${_part}"
    return 1
  fi

  local _parts=( $(bes_str_split ${_version} .) )
  local _index=$(_bes_version_part_index_part ${_part})
  local _old_part=${_parts[${_index}]}
  local _new_part=$(expr ${_old_part} + 1)
  _parts[${_index}]=${_new_part}
  echo ${_parts[*]} | tr ' ' '.'
  return 0
}

_bes_trace_file "end"
