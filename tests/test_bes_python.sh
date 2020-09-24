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

function test_bes_has_python()
{
  bes_assert "[[ $(bes_testing_call_function bes_has_python bad ) == 1 ]]"
}

function test_bes_python_exe_full_version()
{
  local _tmp=/tmp/test_bes_python_exe_full_version_$$
  mkdir -p ${_tmp}
  local _fake_python=${_tmp}/fake_python.sh
  cat > ${_fake_python} << EOF
#!/bin/bash
echo Python 2.7.666 1>&2
exit 0
EOF
  chmod 755 ${_fake_python}

  bes_assert "[[ $(bes_python_exe_full_version ${_fake_python}) == 2.7.666 ]]"

  rm -rf ${_tmp}
}

function test_bes_python_exe_version()
{
  local _tmp=/tmp/test_bes_python_exe_version_$$
  mkdir -p ${_tmp}
  local _fake_python=${_tmp}/fake_python.sh
  cat > ${_fake_python} << EOF
#!/bin/bash
echo Python 2.7.666 1>&2
exit 0
EOF
  chmod 755 ${_fake_python}

  bes_assert "[[ $(bes_python_exe_version ${_fake_python}) == 2.7 ]]"

  rm -rf ${_tmp}
}

function test__bes_python_macos_is_system_python()
{
  if [[ $(bes_system) != "macos" ]]; then
    return 0
  fi
  local _tmp=/tmp/test__bes_python_macos_is_system_python_$$
  mkdir -p ${_tmp}
  local _fake_python=${_tmp}/fake_python.sh
  cat > ${_fake_python} << EOF
#!/bin/bash
echo Python 2.7.666 1>&2
exit 0
EOF
  chmod 755 ${_fake_python}

  bes_assert "[[ $(bes_testing_call_function _bes_python_macos_is_system_python /usr/bin/python ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function _bes_python_macos_is_system_python /usr/bin/python2.7 ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function _bes_python_macos_is_system_python ${_fake_python} ) == 1 ]]"

  rm -rf ${_tmp}
}

_bes_python_macos_is_system_python

bes_testing_run_unit_tests
