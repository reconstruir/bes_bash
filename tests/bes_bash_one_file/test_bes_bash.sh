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

_this_dir="$(_test_this_dir)"
source "${_this_dir}/../../bash/bes_bash_one_file/bes_bash.bash"

source "${_this_dir}/../../bash/bes_bash/_bes_git_unit_test.bash"
_bes_import_filename_set_imported "_bes_git_unit_test.bash"

source "${_this_dir}/../../bash/bes_bash/_bes_python_testing.bash"
_bes_import_filename_set_imported "_bes_python_testing.bash"

_tmp_dir="$(mktemp -d)"
_tmp_file="${_tmp_dir}/test_bes_bash.sh.$$"
rm -f "${_tmp_file}"

_tests_dir="$(bes_path_abs_dir "${_this_dir}/../bes_bash")"

for _test_file in ${_tests_dir}/test_*.sh; do
  cat "${_test_file}" | sed 's/bes_testing_run_unit_tests/\#bes_testing_run_unit_tests/g' | sed 's/source /\#source /g' >> "${_tmp_file}"
done

echo "bes_testing_run_unit_tests" >> "${_tmp_file}"

source "${_tmp_file}"

bes_testing_run_unit_tests
