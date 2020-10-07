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

function test_bes_pip_exe()
{
  local _tmp=/tmp/test_bes_pip_exe$$
  local _fake_python="$(_bes_python_testing_make_testing_python_exe "${_tmp}" python2.7 2.7.666)"
  local _fake_pip=$(_bes_python_testing_make_testing_pip_exe "${_fake_python}" 666.1.2)
  
  bes_assert "[[ $(bes_pip_exe ${_fake_python}) == ${_tmp}/pip2.7 ]]"

  rm -rf ${_tmp}
}

function test_bes_pip_has_pip()
{
  local _tmp=/tmp/test_bes_pip_has_pip$$
  local _fake_python="$(_bes_python_testing_make_testing_python_exe "${_tmp}" python2.7 2.7.667)"
  local _fake_pip=$(_bes_python_testing_make_testing_pip_exe "${_fake_python}" 666.1.2)
  
  #bes_assert "[[ $(bes_testing_call_function bes_pip_has_pip /notthere/foo ) == 1 ]]"
  
  local _save_path="${PATH}"
  PATH="${_tmp}":${PATH}
  bes_assert "[[ $(bes_testing_call_function bes_pip_has_pip ${_fake_python} ) == 0 ]]"
  PATH="${_save_path}"

  rm -rf ${_tmp}
}

function test_bes_pip_exe_version()
{
  local _tmp=/tmp/test_bes_pip_exe_version$$
  local _fake_python="$(_bes_python_testing_make_testing_python_exe "${_tmp}" python2.7 2.7.668)"
  local _fake_pip=$(_bes_python_testing_make_testing_pip_exe "${_fake_python}" 666.1.2)
  
  bes_assert "[[ $(bes_pip_exe_version ${_fake_pip}) == 666.1.2 ]]"

  rm -rf ${_tmp}
}

function test_bes_pip_install()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "test_bes_pip_install: skipping because no builtin python found"
    return 0
  fi
  if bes_pip_has_pip ${_builtin_python}; then
    bes_message "test_bes_pip_install: skipping because pip already found"
    return 0
  fi

  local _tmp=/tmp/test_bes_pip_install$$

  bes_assert "[[ $(bes_testing_call_function bes_pip_has_pip ${_builtin_python} ) == 1 ]]"

  local _PIP_VERSION=20.2.2
  
  export PYTHONUSERBASE="${_tmp}"
  bes_pip_install ${_builtin_python} ${_PIP_VERSION}
  local _install_rv=$?
  
  bes_assert "[[ ${_install_rv} == 0 ]]"

  bes_assert "[[ $(bes_testing_call_function bes_pip_has_pip ${_builtin_python} ) == 0 ]]"

  local _new_pip_exe=$(bes_pip_exe ${_builtin_python})
  
  bes_assert "[[ $(bes_pip_exe_version ${_new_pip_exe}) == ${_PIP_VERSION} ]]"

#20.2.3
  
  #local _fake_python="$(_bes_python_testing_make_testing_python_exe "${_tmp}" python2.7 2.7.669)"
  #local _fake_pip=$(_bes_python_testing_make_testing_pip_exe "${_fake_python}" 666.1.2)
  
  #bes_assert "[[ $(bes_pip_install ${_fake_pip}) == 666.1.2 ]]"

  unset PYTHONUSERBASE
  
  rm -rf ${_tmp}
}

bes_testing_run_unit_tests
