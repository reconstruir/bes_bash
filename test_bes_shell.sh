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

function test_bes_var_set()
{
  bes_var_set FOO 666
  bes_assert "[ $FOO = 666 ]"
}

function test_bes_var_get()
{
  BAR=667
  v=$(bes_var_get BAR)
  bes_assert "[ $v = 667 ]"
}

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
  bes_assert "[ $(bes_path_append /bin /foo/bin) = /bin:/foo/bin ]"
  bes_assert "[ $(bes_path_append /bin:/foo/bin /foo/bin) = /bin:/foo/bin ]"
  bes_assert "[ $(bes_path_append /bin:/foo/bin /foo/bin /bar/bin) = /bin:/foo/bin:/bar/bin ]"
  bes_assert "[ $(bes_path_append /bin:/foo/bin /bin) = /foo/bin:/bin ]"
  bes_assert "[ $(bes_path_append foo bar) = foo:bar ]"
  bes_assert "[ $(bes_path_append foo bar bar foo) = bar:foo ]"
  bes_assert "[ $(bes_path_append /bin:/foo/bin /a\ b | tr ' ' '_') = /bin:/foo/bin:/a_b ]"
  bes_assert "[ $(bes_path_append : /bin/foo) = /bin/foo ]"
}

function test_bes_path_prepend()
{
  bes_assert "[ $(bes_path_prepend /bin /foo/bin) = /foo/bin:/bin ]"
  bes_assert "[ $(bes_path_prepend /foo/bin:/bin /foo/bin) = /foo/bin:/bin ]"
  bes_assert "[ $(bes_path_prepend /foo/bin:/bin /bin) = /bin:/foo/bin ]"
  bes_assert "[ $(bes_path_prepend /foo/bin:/bin /a\ b | tr ' ' '_') = /a_b:/foo/bin:/bin ]"
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
  local _SAVE_PATH="${PATH}"
  PATH=/foo ; bes_env_path_append PATH /bar ; bes_assert "[ ${PATH} = /foo:/bar ]"
  PATH="${_SAVE_PATH}"
}

function test_bes_env_path_prepend()
{
  local _SAVE_PATH="${PATH}"
  PATH=/foo ; bes_env_path_prepend PATH /bar ; bes_assert "[ ${PATH} = /bar:/foo ]"
  PATH="${_SAVE_PATH}"
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

function test_bes_source_dir()
{
  local _pid=$$
  local _tmp=/tmp/test_bes_source_dir_${_pid}
  mkdir -p ${_tmp}
  echo "FOO=foo_${_pid}" > $_tmp/1.sh
  echo "BAR=bar_${_pid}" > $_tmp/2.sh
  echo "BAZ=baz_${_pid}" > $_tmp/3.sh
  (
    bes_source_dir ${_tmp}
    bes_assert "[ ${FOO} = foo_${_pid} ]"
    bes_assert "[ ${BAR} = bar_${_pid} ]"
    bes_assert "[ ${BAZ} = baz_${_pid} ]"
  )
  rm -rf ${_tmp}
}  

function test_bes_to_lower()
{
  bes_assert "[[ $(bes_to_lower FoO) == foo ]]"
  bes_assert "[[ $(bes_to_lower FOO) == foo ]]"
  bes_assert "[[ $(bes_to_lower foo) == foo ]]"
}  

function test_bes_is_true()
{
  function _call_is_true() ( if $(bes_is_true $*); then echo yes; else echo no; fi )
  bes_assert "[[ $(_call_is_true true) == yes ]]"
  bes_assert "[[ $(_call_is_true True) == yes ]]"
  bes_assert "[[ $(_call_is_true TRUE) == yes ]]"
  bes_assert "[[ $(_call_is_true tRuE) == yes ]]"
  bes_assert "[[ $(_call_is_true 1) == yes ]]"
  bes_assert "[[ $(_call_is_true t) == yes ]]"
  bes_assert "[[ $(_call_is_true too) == no ]]"
  bes_assert "[[ $(_call_is_true false) == no ]]"
  bes_assert "[[ $(_call_is_true 0) == no ]]"
}  

function test_bes_is_in_list()
{
  function _call_bes_is_in_list() ( bes_is_in_list "$@"; echo $? )
  bes_assert "[[ $(_call_bes_is_in_list foo foo bar) == 0 ]]"
  bes_assert "[[ $(_call_bes_is_in_list kiwi foo bar) == 1 ]]"
  bes_assert "[[ $(_call_bes_is_in_list "foo " foo bar) == 1 ]]"
  bes_assert "[[ $(_call_bes_is_in_list "foo " "foo " bar) == 0 ]]"
  bes_assert "[[ $(_call_bes_is_in_list foo foo) == 0 ]]"
  bes_assert "[[ $(_call_bes_is_in_list foo bar) == 1 ]]"
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

function test_bes_checksum_file()
{
  local _tmp=/tmp/test_bes_checksum_file_$$
  echo "this is foo" > ${_tmp}
  bes_assert "[[ $(bes_checksum_file md5 ${_tmp}) == 4be8bde80854190cbe801133c6682ecf ]]"
  bes_assert "[[ $(bes_checksum_file sha1 ${_tmp}) == b66399e65f956699e7ece173e73ab2b4021ff1ab ]]"
  bes_assert "[[ $(bes_checksum_file sha224 ${_tmp}) == ff5e833507c74387a06c9aa1b08aad532bb192d1be28b528cd4223cf ]]"
  bes_assert "[[ $(bes_checksum_file sha256 ${_tmp}) == 1573bd8941cf5cd92e31de77bf9cd458b0c32c451a7dfa3b17a2fbdda0f22128 ]]"
  bes_assert "[[ $(bes_checksum_file sha384 ${_tmp}) == 699194214ad6dfa3ee4824be40d271a9b25009d1341623ecab37f378c43b1cb0e052e8344a0379590e22aa3b6bec9ae3 ]]"
  bes_assert "[[ $(bes_checksum_file sha512 ${_tmp}) == 215f8edcc2c879dcc24b1358cae92cbb8007e2cca52de5a2bf80b68503852bbbb1d4825e60748753f93fdfbde0009ad2129be1158a505b91b78a239c2665bcf0 ]]"
  rm -f ${_tmp}
}

function test_bes_checksum_text()
{
  local _text="this is foo"
  function _call_bes_checksum_text() ( bes_checksum_text $1 "${_text}" )
  bes_assert "[[ $(_call_bes_checksum_text md5) == 4be8bde80854190cbe801133c6682ecf ]]"
  bes_assert "[[ $(_call_bes_checksum_text sha1) == b66399e65f956699e7ece173e73ab2b4021ff1ab ]]"
  bes_assert "[[ $(_call_bes_checksum_text sha224) == ff5e833507c74387a06c9aa1b08aad532bb192d1be28b528cd4223cf ]]"
  bes_assert "[[ $(_call_bes_checksum_text sha256) == 1573bd8941cf5cd92e31de77bf9cd458b0c32c451a7dfa3b17a2fbdda0f22128 ]]"
  bes_assert "[[ $(_call_bes_checksum_text sha384) == 699194214ad6dfa3ee4824be40d271a9b25009d1341623ecab37f378c43b1cb0e052e8344a0379590e22aa3b6bec9ae3 ]]"
  bes_assert "[[ $(_call_bes_checksum_text sha512) == 215f8edcc2c879dcc24b1358cae92cbb8007e2cca52de5a2bf80b68503852bbbb1d4825e60748753f93fdfbde0009ad2129be1158a505b91b78a239c2665bcf0 ]]"
}

function test_bes_checksum_dir_files()
{
  local _tmp=/tmp/test_bes_checksum_file_$$
  mkdir -p ${_tmp}/a/b/c/d
  mkdir -p ${_tmp}/z
  echo "this is foo" > ${_tmp}/foo.txt
  echo "this is bar" > ${_tmp}/z/bar.txt
  echo "this is foo bar" > ${_tmp}/"foo bar.txt"
  echo "this is baz" > ${_tmp}/a/b/c/d/baz.txt
  bes_assert "[[ $(bes_checksum_dir_files md5 ${_tmp}) == c7a77a840e37bc0e8f75b1b0c98b5b12 ]]"
  bes_assert "[[ $(bes_checksum_dir_files sha1 ${_tmp}) == 9c7c8010fbbfb58f7d7364f2116ed2e1eeaa59ff ]]"
  bes_assert "[[ $(bes_checksum_dir_files sha224 ${_tmp}) == 0e3789ba6deae30704857cce819c4976714c156adbd2df8557313bf3 ]]"
  bes_assert "[[ $(bes_checksum_dir_files sha256 ${_tmp}) == 08fd0870650d1c59fcef81fbf1782b4186793f00ff3490843274ca34af692c89 ]]"
  bes_assert "[[ $(bes_checksum_dir_files sha384 ${_tmp}) == af0fad2c485de622127076321a5b9de9acbaf0af08b596bef2c23e4b2553593973befebf7a1b9324fbe2087118bdb4e7 ]]"
  bes_assert "[[ $(bes_checksum_dir_files sha512 ${_tmp}) == 7faf90f7200de814894a855af8778cea39365278e569a8e678959793003b5f31b087e96d0b5161e7fcbd5af461bfa995a1063d92b25519b9ded08bc685516dce ]]"
  rm -rf ${_tmp}
}

function test_bes_debug_message()
{
  local _tmp=/tmp/test_bes_debug_message_$$.log
  export BES_LOG_FILE=${_tmp}
  export BES_DEBUG=1
  export _BES_SCRIPT_NAME=myscript
  bes_debug_message foo
  local _actual=$(cat ${_tmp} | tr ' ' '_' | tr '(' '_'| tr ')' '_')
  local _expected="myscript_$$_:_foo"
  bes_assert "[[ ${_expected} == ${_actual} ]]"
  rm -f ${_tmp}
  unset BES_LOG_FILE BES_DEBUG _BES_SCRIPT_NAME
}

function test_bes_debug_message_no_debug()
{
  local _tmp=/tmp/test_bes_debug_message_$$.log
  export BES_LOG_FILE=${_tmp}
  touch ${BES_LOG_FILE}
  export _BES_SCRIPT_NAME=myscript
  bes_debug_message foo
  local _actual=$(cat ${_tmp} | tr ' ' '_' | tr '(' '_'| tr ')' '_')
  test -z "${_actual}"
  #bes_assert "[[ -z ${actual} ]]"
  rm -f ${_tmp}
  unset BES_LOG_FILE BES_DEBUG _BES_SCRIPT_NAME
}

bes_testing_run_unit_tests
