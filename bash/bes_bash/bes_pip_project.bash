#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

bes_log_trace_file pip_project "begin"

bes_import "bes_checksum.bash"

function bes_pip_project_requirements_are_stale()
{
  if [[ $# < 2 ]]; then
    echo "Usage: bes_pip_project_requirements_are_stale project_root_dir reqs_file1 .. reqs_fileN"
    return 1
  fi
  local _project_root_dir="${1}"
  shift
  local _requirements_filename
  for _requirements_filename in $@; do
    local _basename=$(basename "${_requirements_filename}")
    local _checksum_filename="${_project_root_dir}/.requirements_checksums/${_basename}"
    if ! bes_checksum_check_file "${_requirements_filename}" "${_checksum_filename}"; then
      return 0
    fi
  done
  return 1
}

bes_log_trace_file pip_project "end"
