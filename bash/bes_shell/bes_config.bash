#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

_bes_trace_file "begin"

# Read a value from a config file
function bes_config_get()
{
  if [[ $# != 3 ]]; then
    echo "usage: bes_config_get filename section key"
    return 1
  fi
  local _filename="${1}"
  local _section="${2}"
  local _key="${3}"

  bes_file_check bes_config_get "${_filename}" 

  local _line_number
  local _value
  if ! _bes_config_find_entry "${_filename}" ${_section} ${_key} _line_number _entry; then
    bes_message "bes_config_get: no entry found in ${_filename} ${_section} ${_key}"
    return 1
  fi
  echo "${_value}"
  
  return 0
  
  local _line
  local _line_number=1
  local _found_section=false
  while IFS= read -r _line; do
    if [[ "${_line}" == "[${_section}]" ]]; then
      _found_section=true
      #echo FOUND SECTION: "$_line" > /dev/ttys003
    fi
    
#    if [[ "${_line}" =~ "\[${_section}\]"; then
    echo ${_line_number}: "$_line" > /dev/ttys003
    _line_number=$(( _line_number + 1 ))
  done < "${_filename}"
  
  echo cacaptot
  
  return 0
}

function _bes_config_find_entry()
{
  if [[ $# != 5 ]]; then
    echo "usage: _bes_config_find_key filename section key line_number_result_var value_result_var"
    return 1
  fi
  local _filename="${1}"
  local _section="${2}"
  local _key="${3}"
  local _line_number_result_var=${4}
  local _value_result_var=${5}

  local _line
  local _line_number=1
  local _found_section=false
  local _found_entry=false
  local _value
  while IFS= read -r _line; do
    _line_number=$(( _line_number + 1 ))
    if ! ${_found_section}; then
      if [[ "${_line}" == "[${_section}]" ]]; then
        _found_section=true
      fi
    else
      local _next_key="$(bes_string_strip $(echo "${_line}" | awk -F':' '{ print $1; }'))"
      if [[ "${_next_key}" == "${_key}" ]]; then
        _value="$(bes_string_strip $(echo "${_line}" | awk -F':' '{ print $1; }'))"
        _found_entry=true
        break
      fi
#      echo _next_key ${_next_key} > /dev/ttys003
    fi
#    if [[ "${_line}" =~ "\[${_section}\]"; then
    echo ${_found_section}  ${_line_number}: "$_line" > /dev/ttys003
  done < "${_filename}"

  if ${_found_entry}; then
    echo good ${_value} > $(tty)
    echo "${_value}"
    return 0
    eval ${_line_number_result_var}="${_line_number}"
    eval ${_value_result_var}="${_value}"
    return 0
  fi
  
#  local  __resultvar=$1
#  local  myresult='some value'
#  if [[ "$__resultvar" ]]; then
#    eval $__resultvar="'$myresult'"
#  else
#    echo "$myresult"
#  fi

  return 1
}

function poto()
{
  local _result
  myfunc _result
  echo $_result
#  result2=$(myfunc)
#  echo $result2
}

_bes_trace_file "end"