#!/bin/bash

function _this_dir()
{
  local _this_file
  local _this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _this_dir="${_this_file%/*}"
  if [ "${_this_dir}" == "${_this_file}" ]; then
    _this_dir=.
  fi
  echo $(command cd -P "${_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source $(_this_dir)/../bes_shell/bes_shell.sh

function test_bes_shell_var_set()
{
  bes_shell_var_set FOO 666
  bes_shell_assert "[ $FOO = 666 ]"
}

function test_bes_shell_var_get()
{
  BAR=667
  v=$(bes_shell_var_get BAR)
  bes_shell_assert "[ $v = 667 ]"
}

function test_bes_shell_path_dedup()
{
  bes_shell_assert "[ $(bes_shell_path_dedup /bin:/foo:/bin) = /bin:/foo ]"
  bes_shell_assert "[ $(bes_shell_path_dedup /bin:/bin:/bin) = /bin ]"
  bes_shell_assert "[ $(bes_shell_path_dedup /bin::/bin:/bin) = /bin ]"
  bes_shell_assert "[ $(bes_shell_path_dedup /bin::/bin:/bin:::) = /bin ]"
  bes_shell_assert "[ $(bes_shell_path_dedup \"\") = \"\" ]"
  bes_shell_assert "[ $(bes_shell_path_dedup /bin:/foo/bin:/bin) = /bin:/foo/bin ]"
  bes_shell_assert "[ $(bes_shell_path_dedup /bin:/foo/bin:/bin:/a\ b | tr ' ' '_') = /bin:/foo/bin:/a_b ]"
  bes_shell_assert "[ $(bes_shell_path_dedup /bin\ foo:/bin\ foo:/bin\ foo | tr ' ' '_') = /bin_foo ]"
}

function test_bes_shell_path_sanitize()
{
  bes_shell_assert "[ $(bes_shell_path_sanitize /bin:/foo:/bin) = /bin:/foo ]"
  bes_shell_assert "[ $(bes_shell_path_sanitize /bin:/bin:/bin) = /bin ]"
  bes_shell_assert "[ $(bes_shell_path_sanitize :/bin) = /bin ]"
  bes_shell_assert "[ $(bes_shell_path_sanitize /bin::/bin:/bin:::) = /bin ]"
  bes_shell_assert "[ $(bes_shell_path_sanitize \"\") = \"\" ]"
  bes_shell_assert "[ $(bes_shell_path_sanitize :a::::b:) = a:b ]"
  bes_shell_assert "[ $(bes_shell_path_sanitize a:b:c:a:b:c) = a:b:c ]"
  bes_shell_assert "[ $(bes_shell_path_sanitize a\ b:c\ d | tr ' ' '_') = a_b:c_d ]"
  bes_shell_assert "[ $(bes_shell_path_sanitize :a\ b:c\ d | tr ' ' '_') = a_b:c_d ]"
  bes_shell_assert "[ $(bes_shell_path_sanitize a\ b:c\ d: | tr ' ' '_') = a_b:c_d ]"
  bes_shell_assert "[ $(bes_shell_path_sanitize :a\ b:c\ d:a\ b: | tr ' ' '_') = a_b:c_d ]"
}

function test_bes_shell_path_append()
{
  bes_shell_assert "[ $(bes_shell_path_append /bin /foo/bin) = /bin:/foo/bin ]"
  bes_shell_assert "[ $(bes_shell_path_append /bin:/foo/bin /foo/bin) = /bin:/foo/bin ]"
  bes_shell_assert "[ $(bes_shell_path_append /bin:/foo/bin /foo/bin /bar/bin) = /bin:/foo/bin:/bar/bin ]"
  bes_shell_assert "[ $(bes_shell_path_append /bin:/foo/bin /bin) = /foo/bin:/bin ]"
  bes_shell_assert "[ $(bes_shell_path_append foo bar) = foo:bar ]"
  bes_shell_assert "[ $(bes_shell_path_append foo bar bar foo) = bar:foo ]"
  bes_shell_assert "[ $(bes_shell_path_append /bin:/foo/bin /a\ b | tr ' ' '_') = /bin:/foo/bin:/a_b ]"
  bes_shell_assert "[ $(bes_shell_path_append : /bin/foo) = /bin/foo ]"
}

function test_bes_shell_path_prepend()
{
  bes_shell_assert "[ $(bes_shell_path_prepend /bin /foo/bin) = /foo/bin:/bin ]"
  bes_shell_assert "[ $(bes_shell_path_prepend /foo/bin:/bin /foo/bin) = /foo/bin:/bin ]"
  bes_shell_assert "[ $(bes_shell_path_prepend /foo/bin:/bin /bin) = /bin:/foo/bin ]"
  bes_shell_assert "[ $(bes_shell_path_prepend /foo/bin:/bin /a\ b | tr ' ' '_') = /a_b:/foo/bin:/bin ]"
}

function test_bes_shell_path_remove()
{
  bes_shell_assert "[ $(bes_shell_path_remove /bin:/foo/bin /foo/bin) = /bin ]"
  bes_shell_assert "[ $(bes_shell_path_remove /bin:/foo/bin foo/bin) = /bin:/foo/bin ]"
  bes_shell_assert "[ $(bes_shell_path_remove foo:bar bar) = foo ]"
  bes_shell_assert "[ $(bes_shell_path_remove foo:bar bar foo) = ]"
  bes_shell_assert "[ $(bes_shell_path_remove foo:a\ b:bar bar | tr ' ' '_') = foo:a_b ]"
}

function test_bes_shell_env_path_append()
{
  local _SAVE_PATH="${PATH}"
  PATH=/foo ; bes_shell_env_path_append PATH /bar ; bes_shell_assert "[ ${PATH} = /foo:/bar ]"
  PATH="${_SAVE_PATH}"
}

function test_bes_shell_env_path_prepend()
{
  local _SAVE_PATH="${PATH}"
  PATH=/foo ; bes_shell_env_path_prepend PATH /bar ; bes_shell_assert "[ ${PATH} = /bar:/foo ]"
  PATH="${_SAVE_PATH}"
}

function test_bes_shell_env_path_remove()
{
  local _SAVE_PATH="${PATH}"
  PATH=/foo:/bar ; bes_shell_env_path_remove PATH /bar ; bes_shell_assert "[ ${PATH} = /foo ]"
  PATH="${_SAVE_PATH}"
}

function test_bes_shell_variable_map_linux()
{
  if [[ $(bes_shell_system) != 'linux' ]]; then
    return 0
  fi
  bes_shell_assert "[ $(bes_shell_variable_map PATH) = PATH ]"
  bes_shell_assert "[ $(bes_shell_variable_map PYTHONPATH) = PYTHONPATH ]"
  bes_shell_assert "[ $(bes_shell_variable_map LD_LIBRARY_PATH) = LD_LIBRARY_PATH ]"
  bes_shell_assert "[ $(bes_shell_variable_map DYLD_LIBRARY_PATH) = LD_LIBRARY_PATH ]"
}

function test_bes_shell_variable_map_macos()
{
  if [[ $(bes_shell_system) != 'macos' ]]; then
    return 0
  fi
  bes_shell_assert "[ $(bes_shell_variable_map PATH) = PATH ]"
  bes_shell_assert "[ $(bes_shell_variable_map PYTHONPATH) = PYTHONPATH ]"
  bes_shell_assert "[ $(bes_shell_variable_map LD_LIBRARY_PATH) = DYLD_LIBRARY_PATH ]"
  bes_shell_assert "[ $(bes_shell_variable_map DYLD_LIBRARY_PATH) = DYLD_LIBRARY_PATH ]"
}

function test_bes_shell_source_dir()
{
  local _pid=$$
  local _tmp=/tmp/test_bes_shell_source_dir_${_pid}
  mkdir -p ${_tmp}
  echo "FOO=foo_${_pid}" > $_tmp/1.sh
  echo "BAR=bar_${_pid}" > $_tmp/2.sh
  echo "BAZ=baz_${_pid}" > $_tmp/3.sh
  (
    bes_shell_source_dir ${_tmp}
    bes_shell_assert "[ ${FOO} = foo_${_pid} ]"
    bes_shell_assert "[ ${BAR} = bar_${_pid} ]"
    bes_shell_assert "[ ${BAZ} = baz_${_pid} ]"
  )
  rm -rf ${_tmp}
}  

function test_bes_shell_to_lower()
{
  bes_shell_assert "[[ $(bes_shell_to_lower FoO) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_to_lower FOO) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_to_lower foo) == foo ]]"
}  

function test_bes_shell_is_true()
{
  function _call_is_true() ( if $(bes_shell_is_true $*); then echo yes; else echo no; fi )
  bes_shell_assert "[[ $(_call_is_true true) == yes ]]"
  bes_shell_assert "[[ $(_call_is_true True) == yes ]]"
  bes_shell_assert "[[ $(_call_is_true TRUE) == yes ]]"
  bes_shell_assert "[[ $(_call_is_true tRuE) == yes ]]"
  bes_shell_assert "[[ $(_call_is_true 1) == yes ]]"
  bes_shell_assert "[[ $(_call_is_true t) == yes ]]"
  bes_shell_assert "[[ $(_call_is_true too) == no ]]"
  bes_shell_assert "[[ $(_call_is_true false) == no ]]"
  bes_shell_assert "[[ $(_call_is_true 0) == no ]]"
}  

function test_bes_shell_is_in_list()
{
  function _call_bes_shell_is_in_list() ( bes_shell_is_in_list "$@"; echo $? )
  bes_shell_assert "[[ $(_call_bes_shell_is_in_list foo foo bar) == 0 ]]"
  bes_shell_assert "[[ $(_call_bes_shell_is_in_list kiwi foo bar) == 1 ]]"
  bes_shell_assert "[[ $(_call_bes_shell_is_in_list "foo " foo bar) == 1 ]]"
  bes_shell_assert "[[ $(_call_bes_shell_is_in_list "foo " "foo " bar) == 0 ]]"
  bes_shell_assert "[[ $(_call_bes_shell_is_in_list foo foo) == 0 ]]"
  bes_shell_assert "[[ $(_call_bes_shell_is_in_list foo bar) == 1 ]]"
}  

function test_bes_shell_path_head_strip_colon()
{
  bes_shell_assert "[[ $(bes_shell_path_head_strip_colon foo) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_head_strip_colon :foo) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_head_strip_colon ::foo) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_head_strip_colon :::foo) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_head_strip_colon :) == ]]"
  bes_shell_assert "[[ $(bes_shell_path_head_strip_colon ::) == ]]"
  bes_shell_assert "[[ $(bes_shell_path_head_strip_colon :foo:) == foo: ]]"
}  

function test_bes_shell_path_tail_strip_colon()
{
  bes_shell_assert "[[ $(bes_shell_path_tail_strip_colon foo) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_tail_strip_colon foo:) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_tail_strip_colon foo::) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_tail_strip_colon foo:::) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_tail_strip_colon :) == ]]"
  bes_shell_assert "[[ $(bes_shell_path_tail_strip_colon ::) == ]]"
  bes_shell_assert "[[ $(bes_shell_path_tail_strip_colon :foo:) == :foo ]]"
}  

function test_bes_shell_path_strip_colon()
{
  bes_shell_assert "[[ $(bes_shell_path_strip_colon foo) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_strip_colon foo:) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_strip_colon foo::) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_strip_colon foo:::) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_strip_colon :) == ]]"
  bes_shell_assert "[[ $(bes_shell_path_strip_colon ::) == ]]"
  bes_shell_assert "[[ $(bes_shell_path_strip_colon :foo:) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_strip_colon :foo::) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_strip_colon ::foo:) == foo ]]"
  bes_shell_assert "[[ $(bes_shell_path_strip_colon :f:) == f ]]"
}
    
bes_shell_testing_run_unit_tests
