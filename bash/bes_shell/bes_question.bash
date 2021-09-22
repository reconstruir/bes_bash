#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

# Functions to ask questions

_bes_trace_file "begin"

function bes_question_yes_no()
{
  if [[ $# != 2 ]]; then
    echo "usage: bes_question_yes_no var_name message"
    return 1
  fi
  local _CHOICES="[y]es [n]o"
  local _var_name="${1}"
  local _message="${2}"
  local _local_answer
  local _result=1
  while true; do
    read -p "${_message} - ${_CHOICES}: " _local_answer
    case "${_local_answer}" in
      y|Y|yes|YES)
        _result=yes
        break
        ;;
      n|N|no|NO)
        _result=no
        break
        ;;
      *)
        bes_message "Invalid answer: ${_local_answer}.  Please answer: ${_CHOICES}"
    esac
  done
  eval ${_var_name}=${_result}
  return 0
}

_bes_trace_file "end"
