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

# Call a function and convert resulting spaces to underscores to make
# unit tests easier to write
function _call()
{
  local _function=${1}
  shift
  local _result="$(${_function} ${1+"$@"})"
  local _rv=$?
  echo "${_result}" | tr ' ' '_'
  return ${_rv}
}

# Call a function on an environment variable and convert resulting spaces
# to underscores to make unit tests easier to write
function _call_with_env()
{
  local _function=${1}
  shift
  local _value="${1}"
  shift
  _BT1="${_value}"
  ${_function} _BT1 ${1+"$@"}
  local _rv=$?
  echo "${_BT1}" | tr ' ' '_'
  unset _BT1
  return ${_rv}
}

function test_bes_path_dedup()
{
  bes_assert "[ $(_call bes_path_dedup /bin:/foo:/bin) = /bin:/foo ]"
  bes_assert "[ $(_call bes_path_dedup /bin:/bin:/bin) = /bin ]"
  bes_assert "[ $(_call bes_path_dedup /bin::/bin:/bin) = /bin ]"
  bes_assert "[ $(_call bes_path_dedup /bin::/bin:/bin:::) = /bin ]"
  bes_assert "[ $(_call bes_path_dedup \"\") = \"\" ]"
  bes_assert "[ $(_call bes_path_dedup /bin:/foo/bin:/bin) = /bin:/foo/bin ]"
  bes_assert "[ $(_call bes_path_dedup /bin:/foo/bin:/bin:/a\ b) = /bin:/foo/bin:/a_b ]"
  bes_assert "[ $(_call bes_path_dedup /bin\ foo:/bin\ foo:/bin\ foo) = /bin_foo ]"
}

function test_bes_path_clean_rogue_slashes()
{
  bes_assert "[ $(_call bes_path_clean_rogue_slashes /a:/b://c) = /a:/b:/c ]"
  bes_assert "[ $(_call bes_path_clean_rogue_slashes /a:/b:///c) = /a:/b:/c ]"
  bes_assert "[ $(_call bes_path_clean_rogue_slashes /a:/b:"///c d") = /a:/b:/c_d ]"
  bes_assert "[ $(_call bes_path_clean_rogue_slashes /bin//foo:////usr/////bin) = /bin/foo:/usr/bin ]"
}

function test_bes_path_sanitize()
{
  bes_assert "[ $(_call bes_path_sanitize /bin:/foo:/bin) = /bin:/foo ]"
  bes_assert "[ $(_call bes_path_sanitize /bin:/bin:/bin) = /bin ]"
  bes_assert "[ $(_call bes_path_sanitize :/bin) = /bin ]"
  bes_assert "[ $(_call bes_path_sanitize /bin::/bin:/bin:::) = /bin ]"
  bes_assert "[ $(_call bes_path_sanitize \"\") = \"\" ]"
  bes_assert "[ $(_call bes_path_sanitize :a::::b:) = a:b ]"
  bes_assert "[ $(_call bes_path_sanitize a:b:c:a:b:c) = a:b:c ]"
  bes_assert "[ $(_call bes_path_sanitize a\ b:c\ d) = a_b:c_d ]"
  bes_assert "[ $(_call bes_path_sanitize :a\ b:c\ d) = a_b:c_d ]"
  bes_assert "[ $(_call bes_path_sanitize a\ b:c\ d:) = a_b:c_d ]"
  bes_assert "[ $(_call bes_path_sanitize :a\ b:c\ d:a\ b:) = a_b:c_d ]"
  bes_assert "[ $(_call bes_path_sanitize /a://b:///a) = /a:/b ]"
}

function test_bes_path_append()
{
  bes_assert "[ $(_call bes_path_append /bin:/foo/bin /foo/bin) = /bin:/foo/bin ]"
  bes_assert "[ $(_call bes_path_append /bin:/foo/bin /foo/bin /bar/bin) = /bin:/foo/bin:/bar/bin ]"
  bes_assert "[ $(_call bes_path_append /bin:/foo/bin /bin) = /bin:/foo/bin ]"
  bes_assert "[ $(_call bes_path_append foo bar) = foo:bar ]"
  bes_assert "[ $(_call bes_path_append foo bar bar foo) = foo:bar ]"
  bes_assert "[ $(_call bes_path_append /bin:/foo/bin /a\ b) = /bin:/foo/bin:/a_b ]"
  bes_assert "[ $(_call bes_path_append : /bin/foo) = /bin/foo ]"
  bes_assert "[ $(_call bes_path_append /bin:/"a b" /"c d") = /bin:/a_b:/c_d ]"
  bes_assert "[ $(_call bes_path_append /a:/b /c) = /a:/b:/c ]"
}

function test_bes_path_prepend()
{
  bes_assert "[ $(_call bes_path_append /bin /foo/bin) = /foo/bin:/bin ]"
  bes_assert "[ $(_call bes_path_append /foo/bin:/bin /foo/bin) = /foo/bin:/bin ]"
  bes_assert "[ $(_call bes_path_append /foo/bin:/bin /bin) = /bin:/foo/bin ]"
  bes_assert "[ $(_call bes_path_append /foo/bin:/bin "/a b") = /a_b:/foo/bin:/bin ]"
  bes_assert "[ $(_call bes_path_append /foo /bar /baz) = /bar:/baz:/foo ]"
  bes_assert "[ $(_call bes_path_append /foo /bar /baz /bar) = /bar:/baz:/dfoo ]"
  bes_assert "[ $(_call bes_path_append /bin:"/c d" "/a b") = /a_b:/bin:/c_d ]"
  bes_assert "[ $(_call bes_path_append /a:/b /c) = /c:/a:/b ]"
}

function test_bes_path_remove()
{
  bes_assert "[ $(_call bes_path_remove /bin:/foo/bin /foo/bin) = /bin ]"
  bes_assert "[ $(_call bes_path_remove /bin:/foo/bin foo/bin) = /bin:/foo/bin ]"
  bes_assert "[ $(_call bes_path_remove foo:bar bar) = foo ]"
  bes_assert "[ $(_call bes_path_remove foo:bar bar foo) = ]"
  bes_assert "[ $(_call bes_path_remove foo:a\ b:bar bar) = foo:a_b ]"
}

function test_bes_env_path_append()
{
  bes_assert "[ $(_call_with_env bes_env_path_append /foo /bar) = /foo:/bar ]"
  bes_assert "[ $(_call_with_env bes_env_path_append /foo /bar /baz) = /foo:/bar:/baz ]"
  bes_assert "[ $(_call_with_env bes_env_path_append /foo "/a b" /baz) = /foo:/a_b:/baz ]"
  bes_assert "[ $(_call_with_env bes_env_path_append /foo:"/a b" "/c d" "/bar") = /foo:/a_b:/c_d:/bar ]"
}

function test_bes_env_path_prepend()
{
  bes_assert "[ $(_call_with_env bes_env_path_prepend /foo /bar) = /bar:/foo ]"
  bes_assert "[ $(_call_with_env bes_env_path_prepend /foo /bar /baz) = /bar:/baz:/foo ]"
  bes_assert "[ $(_call_with_env bes_env_path_prepend /foo "/a b" /baz) = /a_b:/baz:/foo ]"
  bes_assert "[ $(_call_with_env bes_env_path_prepend /foo /bar "/c d") = /bar:/c_d:/foo ]"
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
  HOME="${_tmp_home}" bes_path_print "/bin:/usr/bin:${_tmp_home}/bin:/Applications/Foo Bar/bin" > ${_tmp}/output
  local _expected
  read -r -d '' _expected <<- EOM
/bin
/usr/bin
~/bin
/Applications/Foo Bar/bin
EOM
  bes_testing_check_file ${_tmp}/output "${_expected}"
  local _rv=$?
  bes_assert "[[ ${_rv} == 0 ]]"
  rm -rf "${_tmp}"
}

bes_testing_run_unit_tests
