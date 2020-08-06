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

_bes_trace_file "end"
