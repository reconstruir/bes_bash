#!/bin/bash

set -e

function main()
{
  local _this_dir="$(_this_dir_make_bes_all)"
  local _bes_shell_dir="${_this_dir}/../bash/bes_shell"

  source "${_bes_shell_dir}/bes_all.bash"
  source "${_bes_shell_dir}/caca.bash"

  _bes_shell_dir="$(bes_path_abs_dir ${_bes_shell_dir})"

  local _tmp_file="${TMPDIR}/bes_all.bash.$$"
  rm -f "${_tmp_file}"

  cat ${_bes_shell_dir}/bes_shell.bash > "${_tmp_file}"
  cat ${_bes_shell_dir}/bes_log.bash >> "${_tmp_file}"
  echo "_bes_import_filename_set_imported \"bes_log.bash\"" >> "${_tmp_file}"
  
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

  local _target="${_bes_shell_dir}/bes_all.bash"

  /bin/cp -f "${_tmp_file}" "${_target}"

  bes_message "Wrote ${_target}"
  
  return 0
}

function _make_bes_all_should_exclude()
{
  local _basename="${1}"
  local _rv
  case "${_basename}" in
    "bes_all.bash"|"bes_shell.bash"|"bes_log.bash")
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
