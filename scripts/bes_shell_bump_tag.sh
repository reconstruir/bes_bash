#!/bin/bash

set -e

function main()
{
  local _this_dir=$(_bes_shell_bump_tag_this_dir)
  source ${_this_dir}/../bes_shell/bes_all.sh
  local _bes_shell=${_this_dir}/../bin/bes_shell.py
  local _python=$(which python3)

  ${_python} ${_bes_shell} git bump_tag -v
  return 0
}

function _bes_shell_bump_tag_this_dir()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  return 0
}

main ${1+"$@"}
