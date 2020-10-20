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

  bes_file_check "${_filename}" 

  local __line_number
  local __value
  if _bes_config_find_entry "${_filename}" ${_section} ${_key} __line_number __value; then
    echo "${__value}"
    return 0
  fi
  echo ""
  return 1
}

# Read a value from a config file
function bes_config_set()
{
  if [[ $# != 4 ]]; then
    echo "usage: bes_config_set filename section key value"
    return 1
  fi
  local _filename="${1}"
  local _section="${2}"
  local _key="${3}"
  local _value="${4}"

  bes_file_check "${_filename}" 

  local __line_number
  local __value
  if _bes_config_find_entry "${_filename}" ${_section} ${_key} __line_number __value; then
    echo "${__value}"
    return 0
  fi
  echo ""
  return 1
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

  local _line_number=0
  local _found_entry=false
  local _value
  local _state=state_expecting_section
  local _line
  local _next_key
  local _next_value
  while IFS= read -r _line; do
    _line_number=$(( _line_number + 1 ))
    local _line_type=$(_bes_config_line_type "${_line}")
    #echo $_line_number: $_state : $_line_type : $_line > /dev/tty
    case ${_state} in
      state_expecting_section)
        case ${_line_type} in
          section)
            if [[ "${_line}" == "[${_section}]" ]]; then
              _state=state_wanted_section
            else
              _state=state_ignore_section
            fi
            ;;
          comment)
            ;;
          entry)
            true
            ;;
          whitespace)
            ;;
        esac
        ;;
      state_ignore_section)
        case ${_line_type} in
          section)
            if [[ "${_line}" == "[${_section}]" ]]; then
              _state=state_wanted_section
            else
              _state=state_ignore_section
            fi
            ;;
          comment|entry|whitespace)
            ;;
        esac
        ;;
      state_wanted_section)
        case ${_line_type} in
          section)
            _state=state_done
            ;;
          comment|whitespace)
            ;;
          entry)
            _next_key="$(bes_string_strip $(echo "${_line}" | awk -F':' '{ print $1; }'))"
            if [[ "${_next_key}" == "${_key}" ]]; then
              _value="$(bes_string_strip $(echo "${_line}" | awk -F':' '{ print $2; }'))"
              _found_entry=true
            fi
            ;;
        esac
        ;;
      state_done)
        break
        ;;
    esac
  done < "${_filename}"

  if ${_found_entry}; then
    eval "${_line_number_result_var}='${_line_number}'"
    eval "${_value_result_var}='${_value}'"
    return 0
  fi
  return 1
}

function _bes_config_line_type()
{
  local _line="${1}"

  if [[ $(echo "${_line}" | cut -b 1) == '[' ]]; then
    echo "section"
    return 0
  fi

  local _stripped_line="$(bes_string_strip "${_line}")"
  if [[ -z "${_stripped_line}" ]]; then
    echo "whitespace"
    return 0
  fi
  if [[ $(echo "${_stripped_line}" | cut -b 1) == '#' ]]; then
    echo "comment"
    return 0
  fi
  echo "entry"
  return 0
}

_bes_trace_file "end"
