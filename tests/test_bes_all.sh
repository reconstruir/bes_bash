#!/bin/bash

function _test_this_dir()
{
  local _this_file
  local _test_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_this_dir="${_this_file%/*}"
  if [ "${_test_this_dir}" == "${_this_file}" ]; then
    _test_this_dir=.
  fi
  echo $(command cd -P "${_test_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_this_dir)"/../bash/bes_shell/bes_all.bash
#bes_import "bes_testing.bash"

function _should_ignore_test()
{
  local _basename="${1}"
  local _rv
  case "${_basename}" in
    "test_bes_all.sh")
      _rv=0
      ;;
    *)
      _rv=1
      ;;
  esac
  return ${_rv}
}

_tmp_file="${TMPDIR}/test_bes_all.sh.$$"
rm -f "${_tmp_file}"

for _test_file in $(_test_this_dir)/*.sh; do
  _basename="$(basename ${_test_file})"
  if ! _should_ignore_test "${_basename}"; then
    cat "${_test_file}" | sed 's/bes_testing_run_unit_tests/\#bes_testing_run_unit_tests/g' | sed 's/source /\#source /g' >> "${_tmp_file}"
  fi
done

echo "bes_testing_run_unit_tests" >> "${_tmp_file}"

source ${_tmp_file}

bes_testing_run_unit_tests
