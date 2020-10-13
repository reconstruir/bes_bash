#!/bin/bash

function _test_bes_pip_this_dir()
{
  local _this_file
  local _test_bes_pip_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_pip_this_dir="${_this_file%/*}"
  if [ "${_test_bes_pip_this_dir}" == "${_this_file}" ]; then
    _test_bes_pip_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_pip_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_pip_this_dir)"/../bash/bes_shell/bes_shell.sh
source "$(_test_bes_pip_this_dir)"/../bash/bes_shell/bes_python.sh
source "$(_test_bes_pip_this_dir)"/../bash/bes_shell/bes_download.sh
source "$(_test_bes_pip_this_dir)"/../bash/bes_shell/bes_pip.sh
source "$(_test_bes_pip_this_dir)"/../bash/bes_shell/_bes_python_testing.sh

function test_bes_pip_exe_version()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "test_bes_pip_exe_version: skipping because no builtin python found"
    return 0
  fi
  local _tmp=/tmp/test_bes_pip_exe_version_$$
  local _fake_python="$(_bes_python_testing_make_testing_python_exe "${_tmp}" python2.7 2.7.668)"
  local _fake_pip=$(_bes_python_testing_make_testing_pip_exe "${_fake_python}" 666.1.2)
  
  bes_assert "[[ $(bes_pip_exe_version ${_builtin_python} ${_fake_pip}) == 666.1.2 ]]"

  rm -rf ${_tmp}
}

function test_bes_pip_exe()
{
  local _tmp=/tmp/test_bes_pip_exe_$$
  local _fake_python="$(_bes_python_testing_make_testing_python_exe "${_tmp}/bin" python2.7 2.7.666)"
  local _fake_pip=$(_bes_python_testing_make_testing_pip_exe "${_fake_python}" 666.1.3)
  
  bes_assert "[[ $(bes_pip_exe ${_fake_python} ${_tmp}) == ${_tmp}/bin/pip2.7 ]]"

  rm -rf ${_tmp}
}

function test_bes_pip_has_pip()
{
  local _tmp=/tmp/test_bes_pip_has_pip_$$
  local _fake_python="$(_bes_python_testing_make_testing_python_exe "${_tmp}/bin" python2.7 2.7.666)"
  local _fake_pip=$(_bes_python_testing_make_testing_pip_exe "${_fake_python}" 666.1.4)
  
  bes_assert "[[ $(bes_testing_call_function bes_pip_has_pip ${_fake_python} ${_tmp} ) == 0 ]]"

  rm -rf ${_tmp}
}

function test_bes_pip_install()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "test_bes_pip_install: skipping because no builtin python found"
    return 0
  fi

  local _tmp=/tmp/test_bes_pip_install_$$

  bes_pip_install "${_builtin_python}" "${_tmp}"
  local _install_rv=$?
  
  bes_assert "[[ ${_install_rv} == 0 ]]"
  
  rm -rf ${_tmp}
}

function test_bes_pip_update()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "test_bes_pip_install: skipping because no builtin python found"
    return 0
  fi

  local _tmp=/tmp/test_bes_pip_update_$$

  bes_pip_install "${_builtin_python}" "${_tmp}"
  local _install_rv=$?
  bes_assert "[[ ${_install_rv} == 0 ]]"

  bes_pip_update "${_builtin_python}" "${_tmp}" 20.2.1
  local _update_rv=$?
  bes_assert "[[ ${_update_rv} == 0 ]]"

  local _new_pip_exe="$(bes_pip_exe ${_builtin_python} "${_tmp}")"
  bes_assert "[[ $(bes_pip_exe_version ${_builtin_python} ${_new_pip_exe}) == 20.2.1 ]]"

  bes_pip_update "${_builtin_python}" "${_tmp}" 20.2.2
  _update_rv=$?
  bes_assert "[[ ${_update_rv} == 0 ]]"
  bes_assert "[[ $(bes_pip_exe_version ${_builtin_python} ${_new_pip_exe}) == 20.2.2 ]]"
  
  rm -rf ${_tmp}
}

function test_bes_pip_ensure()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "test_bes_pip_install: skipping because no builtin python found"
    return 0
  fi

  local _tmp=/tmp/test_bes_pip_ensure_$$

  bes_pip_ensure "${_builtin_python}" "${_tmp}" 20.2.1
  local _ensure_rv=$?
  bes_assert "[[ ${_ensure_rv} == 0 ]]"
  local _new_pip_exe="$(bes_pip_exe ${_builtin_python} "${_tmp}")"
  bes_assert "[[ $(bes_pip_exe_version ${_builtin_python} ${_new_pip_exe}) == 20.2.1 ]]"

  bes_pip_ensure "${_builtin_python}" "${_tmp}" 20.2.2
  _ensure_rv=$?
  bes_assert "[[ ${_ensure_rv} == 0 ]]"
  bes_assert "[[ $(bes_pip_exe_version ${_builtin_python} ${_new_pip_exe}) == 20.2.2 ]]"
  
  rm -rf ${_tmp}
}

function test_bes_pip_install_package()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "test_bes_pip_install_package: skipping because no builtin python found"
    return 0
  fi

  local _tmp=/tmp/test_bes_pip_install_package_$$
  local _user_site_dir="${_tmp}/lib/python/site-packages"
  
  bes_pip_ensure "${_builtin_python}" "${_tmp}" 20.2.3
  local _pip_exe=$(bes_pip_exe ${_builtin_python} "${_tmp}")
  
  local _test_pip_dot_py=${_tmp}/test_pip.py
  cat > ${_test_pip_dot_py} << EOF
try:
  import requests
  print(requests.__file__)
  raise SystemExit(0)
except Exception as ex:
  raise SystemExit(1)
EOF

  local _tmp_test_output=${_tmp}/test_output.txt
  
  PYTHONPATH="${_user_site_dir}" ${_builtin_python} ${_test_pip_dot_py} >& "${_tmp_test_output}"
  local _test_rv=$?
  bes_assert "[[ ${_test_rv} == 1 ]]"

  bes_pip_install_package "${_builtin_python}" "${_pip_exe}" requests
  local _install_rv=$?
  bes_assert "[[ ${_install_rv} == 0 ]]"

  PYTHONPATH="${_user_site_dir}" ${_builtin_python} ${_test_pip_dot_py} >& "${_tmp_test_output}"
  local _test_rv=$?

  bes_assert "[[ ${_test_rv} == 0 ]]"
  local _output=$(cat "${_tmp_test_output}")

  bes_assert "[[ $(bes_testing_call_function bes_str_starts_with ${_output} ${_user_site_dir} ) == 0 ]]"
  
  rm -rf ${_tmp}
}

bes_testing_run_unit_tests
