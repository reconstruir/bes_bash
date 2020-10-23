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
    local _token_type=$(_bes_config_token_type "${_line}")
    #echo $_line_number: $_state : $_token_type : $_line > /dev/tty
    case ${_state} in
      state_expecting_section)
        case ${_token_type} in
          token_section)
            if [[ "${_line}" == "[${_section}]" ]]; then
              _state=state_wanted_section
            else
              _state=state_ignore_section
            fi
            ;;
          token_comment)
            ;;
          token_entry)
            true
            ;;
          token_whitespace)
            ;;
        esac
        ;;
      state_ignore_section)
        case ${_token_type} in
          token_section)
            if [[ "${_line}" == "[${_section}]" ]]; then
              _state=state_wanted_section
            else
              _state=state_ignore_section
            fi
            ;;
          token_comment|entry|whitespace)
            ;;
        esac
        ;;
      state_wanted_section)
        case ${_token_type} in
          token_section)
            _state=state_done
            ;;
          token_comment|token_whitespace)
            ;;
          token_entry)
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

# ' ' @SPACE@
# ':' @COLON@
function _bes_config_text_escape()
{
  local _text="${1}"
  local _patterns=( "s/@SPACE@/%%SPACE%%/g" "s/@COLON@/%%COLON%%/g" "s/ /@SPACE@/g" "s/:/@COLON@/g" )
  local _pattern
  local _tmp_command_file=/tmp/tmp__bes_config_text_unescape_command_file_$$
  rm -f "${_tmp_command_file}"
  for _pattern in "${_patterns[@]}"; do
    echo "${_pattern}" >> "${_tmp_command_file}"
  done
  echo "${_text}" | sed -f "${_tmp_command_file}"
  rm -f "${_tmp_command_file}"
  return 0
}

# undo the action of _bes_config_text_escape
function _bes_config_text_unescape()
{
  local _text="${1}"
  local _patterns=( "s/%%SPACE%%/@SPACE@/g" "s/%%COLON%%/@COLON@/g" "s/@SPACE@/ /g" "s/@COLON@/:/g" )
  local _pattern
  local _tmp_command_file=/tmp/tmp__bes_config_text_unescape_command_file_$$
  rm -f "${_tmp_command_file}"
  for _pattern in "${_patterns[@]}"; do
    echo "${_pattern}" >> "${_tmp_command_file}"
  done
  echo "${_text}" | sed -f "${_tmp_command_file}"
  rm -f "${_tmp_command_file}"
  return 0
}

function _bes_config_parse_section_name()
{
  local _text="${1}"
  if [[ "${_text}" =~ \[(.+)\] ]]; then
    local _section_name="${BASH_REMATCH[1]}"
    if [[ -z "${_section_name}" ]]; then
      return 1
    fi
    echo ${BASH_REMATCH[1]}
    return 0
  fi
  return 1
}

function _bes_config_parse_entry()
{
  local _text="${1}"

  local _key="$(bes_string_partition "${_text}" ":" | head -1)"
  local _delim="$(bes_string_partition "${_text}" ":" | tail -2 | head -1)"
  local _valye="$(bes_string_partition "${_text}" ":" | tail -1)"

  if [[ ${_delim} != ":" ]]; then
    return 1
  fi

  local _escaped_key=$(_bes_config_text_escape "${_key}")
  local _escaped_value=$(_bes_config_text_escape "${_value}")
  echo ${_escaped_key}:${_escaped_value}
  return 0
}

# Tokenize a config file and produce tokens as such
# ${token_type}:${line_number}:${text}:${key}:${value}
function _bes_config_tokenize()
{
  if [[ $# != 1 ]]; then
    echo "usage: _bes_config_tokenize filename"
    return 1
  fi
  local _filename="${1}"
  local _line_number=1
  local _line
  local _token_type
  local _text
  local _rest
  while IFS= read -r _line; do
    _token_type=$(_bes_config_token_type "${_line}")
    case ${_token_type} in
      token_section)
        _text="$(_bes_config_parse_section_name "${_line}")"
        ;;
      token_comment)
        _text="$(bes_string_strip "${_line}")"
        ;;
      token_entry)
        _text=$(_bes_config_text_escape "${_line}")
        _rest=$(_bes_config_parse_entry "${_line}")
        ;;
      token_whitespace)
        _text=""
        ;;
    esac
    echo ${_token_type}:${_line_number}:${_text}:${_rest}
    _line_number=$(( _line_number + 1 ))
  done < "${_filename}"
  return 0
}

function _bes_config_token_type()
{
  local _line="${1}"

  if [[ $(echo "${_line}" | cut -b 1) == '[' ]]; then
    echo "token_section"
    return 0
  fi

  local _stripped_line="$(bes_string_strip "${_line}")"
  if [[ -z "${_stripped_line}" ]]; then
    echo "token_whitespace"
    return 0
  fi
  if [[ $(echo "${_stripped_line}" | cut -b 1) == '#' ]]; then
    echo "token_comment"
    return 0
  fi
  echo "token_entry"
  return 0
}

_bes_trace_file "end"
