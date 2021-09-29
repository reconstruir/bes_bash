#!/bin/bash

set -e

function main()
{
  if [[ $# != 1 ]]; then
    echo "usage: make_bes_bash.sh target_filename"
    return 1
  fi
  local _target_filename="${1}"
  local _this_dir="$(_this_dir_make_bes_all)"
  local _bes_shell_dir="${_this_dir}/../bash/bes_bash"

  source "${_bes_shell_dir}/bes_basic.bash"
  bes_import "bes_path.bash"

  _target_filename="$(bes_path_abs_file ${_target_filename})"
  _bes_shell_dir="$(bes_path_abs_dir ${_bes_shell_dir})"

  local _tmp_file="${TMPDIR}/bes_basic.bash.$$"
  rm -f "${_tmp_file}"

  cat ${_bes_shell_dir}/bes_basic.bash > "${_tmp_file}"
  
  local _file
  for _file in ${_bes_shell_dir}/bes_*.bash; do
    local _basename="$(basename ${_file})"
    if ! _make_bes_all_should_exclude "${_basename}"; then
      echo "_bes_import_filename_set_imported \"${_basename}\"" >> "${_tmp_file}"
    fi
  done

  for _file in ${_bes_shell_dir}/bes_*.bash; do
    local _basename="$(basename ${_file})"
    if ! _make_bes_all_should_exclude "${_basename}"; then
      cat "${_file}" >> "${_tmp_file}"
    fi
  done

  echo _target_filename $_target_filename
  _target_filename_dir="$(dirname ${_target_filename})"
  mkdir -p "${_target_filename_dir}"

  /bin/cp -f "${_tmp_file}" "${_target_filename}"

  bes_message "Wrote ${_target_filename}"
  
  return 0
}

function _make_bes_all_should_exclude()
{
  local _basename="${1}"
  local _rv
  case "${_basename}" in
    "bes_all.bash"|"bes_basic.bash")
      _rv=0
      ;;
    *)
      _rv=1
      ;;
  esac
  return ${_rv}
}

function _this_dir_make_bes_all()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  return 0
}

main ${1+"$@"}
