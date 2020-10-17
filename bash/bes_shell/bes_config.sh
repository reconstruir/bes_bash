#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

_bes_trace_file "begin"

# Read a value from a config file
function bes_config_get()
{
  if [[ $# != 2 ]]; then
    echo "usage: bes_config_get filename key"
    return 1
  fi
  local _filename="${1}"
  local _key="${2}"

  bes_file_check bes_config_get "${_filename}" 

  local _line
  while IFS= read -r _line; do
    echo LINE: "$_line"
  done < "${_filename}"
  
  echo caca
  
  return 0
}

_bes_trace_file "end"
