#!/bin/bash

function _test_bes_path_this_dir()
{
  local _this_file
  local _test_bes_path_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_path_this_dir="${_this_file%/*}"
  if [ "${_test_bes_path_this_dir}" == "${_this_file}" ]; then
    _test_bes_path_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_path_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_var.bash
source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_log.bash
source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_system.bash
source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_list.bash
source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_path.bash
source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_testing.bash

source "$(_test_bes_path_this_dir)"/../bash/bes_shell/bes_shell.bash # for bes_sytem

function test_bes_path_dedup()
{
  bes_assert "[ $(bes_path_dedup /bin:/foo:/bin) = /bin:/foo ]"
  bes_assert "[ $(bes_path_dedup /bin:/bin:/bin) = /bin ]"
  bes_assert "[ $(bes_path_dedup /bin::/bin:/bin) = /bin ]"
  bes_assert "[ $(bes_path_dedup /bin::/bin:/bin:::) = /bin ]"
  bes_assert "[ $(bes_path_dedup \"\") = \"\" ]"
  bes_assert "[ $(bes_path_dedup /bin:/foo/bin:/bin) = /bin:/foo/bin ]"
  bes_assert "[ $(bes_path_dedup /bin:/foo/bin:/bin:/a\ b | tr ' ' '_') = /bin:/foo/bin:/a_b ]"
  bes_assert "[ $(bes_path_dedup /bin\ foo:/bin\ foo:/bin\ foo | tr ' ' '_') = /bin_foo ]"
}

function test_bes_path_sanitize()
{
  bes_assert "[ $(bes_path_sanitize /bin:/foo:/bin) = /bin:/foo ]"
  bes_assert "[ $(bes_path_sanitize /bin:/bin:/bin) = /bin ]"
  bes_assert "[ $(bes_path_sanitize :/bin) = /bin ]"
  bes_assert "[ $(bes_path_sanitize /bin::/bin:/bin:::) = /bin ]"
  bes_assert "[ $(bes_path_sanitize \"\") = \"\" ]"
  bes_assert "[ $(bes_path_sanitize :a::::b:) = a:b ]"
  bes_assert "[ $(bes_path_sanitize a:b:c:a:b:c) = a:b:c ]"
  bes_assert "[ $(bes_path_sanitize a\ b:c\ d | tr ' ' '_') = a_b:c_d ]"
  bes_assert "[ $(bes_path_sanitize :a\ b:c\ d | tr ' ' '_') = a_b:c_d ]"
  bes_assert "[ $(bes_path_sanitize a\ b:c\ d: | tr ' ' '_') = a_b:c_d ]"
  bes_assert "[ $(bes_path_sanitize :a\ b:c\ d:a\ b: | tr ' ' '_') = a_b:c_d ]"
}

function test_bes_path_append()
{
  function _call()
  {
    local _p="${1}"
    shift
    local _result=$(bes_path_append "${_p}" ${1+"$@"})
    echo "${_result}" | tr ' ' '_'
    return $?
  }
  bes_assert "[ $(_call /bin:/foo/bin /foo/bin) = /bin:/foo/bin ]"
  bes_assert "[ $(_call /bin:/foo/bin /foo/bin /bar/bin) = /bin:/foo/bin:/bar/bin ]"
  bes_assert "[ $(_call /bin:/foo/bin /bin) = /bin:/foo/bin ]"
  bes_assert "[ $(_call foo bar) = foo:bar ]"
  bes_assert "[ $(_call foo bar bar foo) = foo:bar ]"
  bes_assert "[ $(_call /bin:/foo/bin /a\ b) = /bin:/foo/bin:/a_b ]"
  bes_assert "[ $(_call : /bin/foo) = /bin/foo ]"
  bes_assert "[ $(_call /bin:/"a b" /"c d") = /bin:/a_b:/c_d ]"
}

function test_bes_path_prepend()
{
  function _call()
  {
    local _p="${1}"
    shift
    local _result=$(bes_path_prepend "${_p}" ${1+"$@"})
    echo "${_result}" | tr ' ' '_'
    return $?
  }
  bes_assert "[ $(_call /bin /foo/bin) = /foo/bin:/bin ]"
  bes_assert "[ $(_call /foo/bin:/bin /foo/bin) = /foo/bin:/bin ]"
  bes_assert "[ $(_call /foo/bin:/bin /bin) = /bin:/foo/bin ]"
  bes_assert "[ $(_call /foo/bin:/bin "/a b") = /a_b:/foo/bin:/bin ]"
  bes_assert "[ $(_call /foo /bar /baz) = /bar:/baz:/foo ]"
  bes_assert "[ $(_call /foo /bar /baz /bar) = /bar:/baz:/foo ]"
  bes_assert "[ $(_call /bin:"/c d" "/a b") = /a_b:/bin:/c_d ]"
}

function test_bes_path_remove()
{
  bes_assert "[ $(bes_path_remove /bin:/foo/bin /foo/bin) = /bin ]"
  bes_assert "[ $(bes_path_remove /bin:/foo/bin foo/bin) = /bin:/foo/bin ]"
  bes_assert "[ $(bes_path_remove foo:bar bar) = foo ]"
  bes_assert "[ $(bes_path_remove foo:bar bar foo) = ]"
  bes_assert "[ $(bes_path_remove foo:a\ b:bar bar | tr ' ' '_') = foo:a_b ]"
}

function test_bes_env_path_append()
{
  function _call()
  {
    _BT1="${1}"
    shift
    bes_env_path_append _BT1 ${1+"$@"}
    echo "${_BT1}" | tr ' ' '_'
    unset _BT1
    return $?
  }
  bes_assert "[ $(_call /foo /bar) = /foo:/bar ]"
  bes_assert "[ $(_call /foo /bar /baz) = /foo:/bar:/baz ]"
  bes_assert "[ $(_call /foo "/a b" /baz) = /foo:/a_b:/baz ]"
  bes_assert "[ $(_call /foo:"/a b" "/c d" "/bar") = /foo:/a_b:/c_d:/bar ]"
}

function test_bes_env_path_prepend()
{
  function _call()
  {
    _BT1="${1}"
    shift
    bes_env_path_prepend _BT1 ${1+"$@"}
    echo "${_BT1}" | tr ' ' '_'
    unset _BT1
    return $?
  }
  bes_assert "[ $(_call /foo /bar) = /bar:/foo ]"
  bes_assert "[ $(_call /foo /bar /baz) = /bar:/baz:/foo ]"
  bes_assert "[ $(_call /foo "/a b" /baz) = /a_b:/baz:/foo ]"
  bes_assert "[ $(_call /foo /bar "/c d") = /bar:/c_d:/foo ]"
}

function test_bes_env_path_remove()
{
  local _SAVE_PATH="${PATH}"
  PATH=/foo:/bar ; bes_env_path_remove PATH /bar ; bes_assert "[ ${PATH} = /foo ]"
  PATH="${_SAVE_PATH}"
}

function test_bes_variable_map_linux()
{
  if [[ $(bes_system) != 'linux' ]]; then
    return 0
  fi
  bes_assert "[ $(bes_variable_map PATH) = PATH ]"
  bes_assert "[ $(bes_variable_map PYTHONPATH) = PYTHONPATH ]"
  bes_assert "[ $(bes_variable_map LD_LIBRARY_PATH) = LD_LIBRARY_PATH ]"
  bes_assert "[ $(bes_variable_map DYLD_LIBRARY_PATH) = LD_LIBRARY_PATH ]"
}

function test_bes_variable_map_macos()
{
  if [[ $(bes_system) != 'macos' ]]; then
    return 0
  fi
  bes_assert "[ $(bes_variable_map PATH) = PATH ]"
  bes_assert "[ $(bes_variable_map PYTHONPATH) = PYTHONPATH ]"
  bes_assert "[ $(bes_variable_map LD_LIBRARY_PATH) = DYLD_LIBRARY_PATH ]"
  bes_assert "[ $(bes_variable_map DYLD_LIBRARY_PATH) = DYLD_LIBRARY_PATH ]"
}

function test_bes_path_head_strip_colon()
{
  bes_assert "[[ $(bes_path_head_strip_colon foo) == foo ]]"
  bes_assert "[[ $(bes_path_head_strip_colon :foo) == foo ]]"
  bes_assert "[[ $(bes_path_head_strip_colon ::foo) == foo ]]"
  bes_assert "[[ $(bes_path_head_strip_colon :::foo) == foo ]]"
  bes_assert "[[ $(bes_path_head_strip_colon :) == ]]"
  bes_assert "[[ $(bes_path_head_strip_colon ::) == ]]"
  bes_assert "[[ $(bes_path_head_strip_colon :foo:) == foo: ]]"
}  

function test_bes_path_tail_strip_colon()
{
  bes_assert "[[ $(bes_path_tail_strip_colon foo) == foo ]]"
  bes_assert "[[ $(bes_path_tail_strip_colon foo:) == foo ]]"
  bes_assert "[[ $(bes_path_tail_strip_colon foo::) == foo ]]"
  bes_assert "[[ $(bes_path_tail_strip_colon foo:::) == foo ]]"
  bes_assert "[[ $(bes_path_tail_strip_colon :) == ]]"
  bes_assert "[[ $(bes_path_tail_strip_colon ::) == ]]"
  bes_assert "[[ $(bes_path_tail_strip_colon :foo:) == :foo ]]"
}  

function test_bes_path_strip_colon()
{
  bes_assert "[[ $(bes_path_strip_colon foo) == foo ]]"
  bes_assert "[[ $(bes_path_strip_colon foo:) == foo ]]"
  bes_assert "[[ $(bes_path_strip_colon foo::) == foo ]]"
  bes_assert "[[ $(bes_path_strip_colon foo:::) == foo ]]"
  bes_assert "[[ $(bes_path_strip_colon :) == ]]"
  bes_assert "[[ $(bes_path_strip_colon ::) == ]]"
  bes_assert "[[ $(bes_path_strip_colon :foo:) == foo ]]"
  bes_assert "[[ $(bes_path_strip_colon :foo::) == foo ]]"
  bes_assert "[[ $(bes_path_strip_colon ::foo:) == foo ]]"
  bes_assert "[[ $(bes_path_strip_colon :f:) == f ]]"
}

function test_bes_path_is_abs()
{
  bes_assert "[[ $(bes_testing_call_function bes_path_is_abs foo ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_path_is_abs /foo ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_path_is_abs //foo ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_path_is_abs foo/ ) == 1 ]]"
}

function test_bes_path_is_symlink()
{
  local _tmp=/tmp/test_bes_path_is_symlink_$$
  mkdir -p ${_tmp}
  echo foo > ${_tmp}/file
  ( cd ${_tmp} && ln -s file link )
  bes_assert "[[ $(bes_testing_call_function bes_path_is_symlink ${_tmp}/file ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_path_is_symlink ${_tmp}/link ) == 0 ]]"
  rm -rf ${_tmp}
}

function test_bes_path_prepend()
{
  local _tmp="$(bes_testing_make_temp_dir test_bes_path_print)"
  local _tmp_home="${_tmp}/home"
  HOME="${_tmp_home}" bes_path_print "/bin:/usr/bin:${_tmp_home}/bin" > ${_tmp}/output
  local _expected
  read -r -d '' _expected <<- EOM
/bin
/usr/bin
~/bin
EOM
  bes_testing_check_file ${_tmp}/output "${_expected}"
  local _rv=$?
  bes_assert "[[ ${_rv} == 0 ]]"
  rm -rf "${_tmp}"
}

bes_testing_run_unit_tests
