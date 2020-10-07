#!/bin/bash

function _test_bes_python_this_dir()
{
  local _this_file
  local _test_bes_python_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_python_this_dir="${_this_file%/*}"
  if [ "${_test_bes_python_this_dir}" == "${_this_file}" ]; then
    _test_bes_python_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_python_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_python_this_dir)"/../bash/bes_shell/bes_shell.sh
source "$(_test_bes_python_this_dir)"/../bash/bes_shell/bes_python.sh

function _python_testing_make_testing_python_exe()
{
  if [[ $# != 3 ]]; then
    bes_message "Usage: _python_testing_make_testing_python_exe where basename full_version"
    return 1
  fi
  local _where="${1}"
  local _basename="${2}"
  local _full_version="${3}"
  mkdir -p ${_where}
  local _exe="${_where}/${_basename}"
  cat > "${_exe}" << EOF
#!/bin/bash
echo Python ${_full_version} 1>&2
exit 0
EOF
  chmod 755 ${_exe}
  echo "${_exe}"
  return 0
}

function test_bes_has_python()
{
  bes_assert "[[ $(bes_testing_call_function bes_has_python bad ) == 1 ]]"
}

function test_bes_python_exe_full_version()
{
  local _tmp=/tmp/test_bes_python_exe_full_version_$$
  local _fake_python="$(_python_testing_make_testing_python_exe "${_tmp}" fake_python.sh 2.7.666)"

  bes_assert "[[ $(bes_python_exe_full_version ${_fake_python}) == 2.7.666 ]]"

  rm -rf ${_tmp}
}

function test_bes_python_exe_version()
{
  local _tmp=/tmp/test_bes_python_exe_version_$$
  local _fake_python="$(_python_testing_make_testing_python_exe "${_tmp}" fake_python.sh 2.7.666)"
  bes_assert "[[ $(bes_python_exe_version ${_fake_python}) == 2.7 ]]"

  rm -rf ${_tmp}
}

function test__bes_python_macos_is_builtin()
{
  if [[ $(bes_system) != "macos" ]]; then
    return 0
  fi
  local _tmp=/tmp/test__bes_python_macos_is_builtin_$$
  local _fake_python="$(_python_testing_make_testing_python_exe "${_tmp}" fake_python.sh 2.7.666)"
  
  bes_assert "[[ $(bes_testing_call_function _bes_python_macos_is_builtin /usr/bin/python ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function _bes_python_macos_is_builtin /usr/bin/python2.7 ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function _bes_python_macos_is_builtin ${_fake_python} ) == 1 ]]"

  rm -rf ${_tmp}
}

bes_testing_run_unit_tests
