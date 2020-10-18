#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

# Functions to deal with strings

_bes_trace_file "begin"

# Strip whitespace from the head of a string
# From https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
function bes_string_strip_head()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_strip_head str"
    return 1
  fi
  local _str="${1}"
  local _stripped="$(echo -e "${_str}" | sed -e 's/^[[:space:]]*//')"
  echo "${_stripped}"
  return 0
}

# Strip whitespace from the tail of a string
# From https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
function bes_string_strip_tail()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_strip_head str"
    return 1
  fi
  local _str="${1}"
  local _stripped="$(echo -e "${_str}" | sed -e 's/[[:space:]]*$//')"
  echo "${_stripped}"
  return 0
}

# Strip whitespace from both the head and tail of a string
# From https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
function bes_string_strip()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_strip_head str"
    return 1
  fi
  local _str="${1}"
  local _stripped="$(echo -e "${_str}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  echo "${_stripped}"
  return 0
}

# Partition a string into left, separator and right.  delimiter needs to be a char
function bes_string_partition()
{
  if [[ $# != 2 ]]; then
    bes_message "Usage: bes_string_partition str delimiter"
    return 1
  fi
  local _str="${1}"
  local _delimiter=${2}

  local _left="$(echo "${_str}" | cut -d${_delimiter} -f 1)"
  local _right
  local _delimiter
  if [[ "${_left}" != "${_str}" ]]; then
    local _left_len=$(echo ${#_left})
    local _cut_index=$(( _left_len + 2 ))
    _right="$(echo "${_str}" | cut -b${_cut_index}-)"
    _delimiter=${_delimiter}
  fi

  echo "${_left}"
  echo "${_delimiter}"
  echo "${_right}"
  
  return 0
}

_bes_trace_file "end"
