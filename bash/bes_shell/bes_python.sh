#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

# Functions to deal with python

_bes_trace_file "begin"

# Download a url to a file with optional username and password.
# uses curl or wget dependning on which one is found
function bes_has_python()
{
  if [[ $# != 1 ]]; then
    bes_message "Usage: bes_has_python version"
    return 1
  fi
  local _version=${1}
  local _python_exe=python${_version}
  if bes_has_program ${_python_exe}; then
    return 0
  fi
  return 1
}

_bes_trace_file "end"
