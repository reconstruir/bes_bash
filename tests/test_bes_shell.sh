#!/bin/bash

function _test_bes_shell_this_dir()
{
  local _this_file
  local _test_bes_shell_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_shell_this_dir="${_this_file%/*}"
  if [ "${_test_bes_shell_this_dir}" == "${_this_file}" ]; then
    _test_bes_shell_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_shell_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source $(_test_bes_shell_this_dir)/../bash/bes_shell/bes_shell.sh

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
  bes_assert "[[ $(bes_testing_call_function bes_is_true true) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_true True) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_true TRUE) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_true tRuE) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_true 1) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_true t) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_true too) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_true false) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_true 0) == 1 ]]"
}  

function test_bes_is_in_list()
{
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list foo foo bar) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list kiwi foo bar) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list "foo " foo bar) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list "foo " "foo " bar) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list foo foo) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_is_in_list foo bar) == 1 ]]"
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
  bes_assert "[[ $(bes_checksum_file sha256 ${_tmp}) == 1573bd8941cf5cd92e31de77bf9cd458b0c32c451a7dfa3b17a2fbdda0f22128 ]]"
  bes_assert "[[ $(bes_checksum_file sha512 ${_tmp}) == 215f8edcc2c879dcc24b1358cae92cbb8007e2cca52de5a2bf80b68503852bbbb1d4825e60748753f93fdfbde0009ad2129be1158a505b91b78a239c2665bcf0 ]]"
  rm -f ${_tmp}
}

function test_bes_checksum_text()
{
  local _text="this is foo"
  function _call_bes_checksum_text() ( bes_checksum_text $1 "${_text}" )
  bes_assert "[[ $(_call_bes_checksum_text md5) == 4be8bde80854190cbe801133c6682ecf ]]"
  bes_assert "[[ $(_call_bes_checksum_text sha1) == b66399e65f956699e7ece173e73ab2b4021ff1ab ]]"
  bes_assert "[[ $(_call_bes_checksum_text sha256) == 1573bd8941cf5cd92e31de77bf9cd458b0c32c451a7dfa3b17a2fbdda0f22128 ]]"
  bes_assert "[[ $(_call_bes_checksum_text sha512) == 215f8edcc2c879dcc24b1358cae92cbb8007e2cca52de5a2bf80b68503852bbbb1d4825e60748753f93fdfbde0009ad2129be1158a505b91b78a239c2665bcf0 ]]"
}

function xtest_bes_checksum_dir_files()
{
  local _tmp=/tmp/test_bes_checksum_file_$$
  mkdir -p ${_tmp}/a/b/c/d
  mkdir -p ${_tmp}/z
  echo "this is foo" > ${_tmp}/foo.txt
  echo "this is bar" > ${_tmp}/z/bar.txt
  echo "this is foo bar" > ${_tmp}/"foo bar.txt"
  echo "this is baz" > ${_tmp}/a/b/c/d/baz.txt
  bes_assert "[[ $(bes_checksum_dir_files md5 ${_tmp}) == 404ded59fd3628453e8b11c052cf1c72 ]]"
  bes_assert "[[ $(bes_checksum_dir_files sha1 ${_tmp}) == c7e02b7e5010d15723d7bf3daae0a6829bcead5e ]]"
  bes_assert "[[ $(bes_checksum_dir_files sha256 ${_tmp}) == 1dfa06817a2e5d9d60f28ae131f6784f5fd9b3beae4d23051b9a9cb487889e4d ]]"
  bes_assert "[[ $(bes_checksum_dir_files sha512 ${_tmp}) == 6f6957b4818efd8d22554555f6b23ef016cf43faa68f6bb0a96afd617cf9d82be19deb9e34746ac5ddadb5395296854c40bfe0c2965a81cb1a2cd527e9f0af4d ]]"
  rm -rf ${_tmp}
}

function xtest_bes_checksum_manifest()
{
  local _tmp=/tmp/test_bes_checksum_file_$$
  local _dir=${_tmp}/dir
  local _manifest=${_tmp}/manifest
  mkdir -p ${_dir}/a/b/c/d
  mkdir -p ${_dir}/z
  echo "this is foo" > ${_dir}/foo.txt
  echo "this is bar" > ${_dir}/z/bar.txt
  echo "this is foo bar" > ${_dir}/"foo bar.txt"
  echo "this is baz" > ${_dir}/a/b/c/d/baz.txt
  ( cd ${_dir} && find . -type f -print > ${_manifest} )
  bes_assert "[[ $(bes_checksum_manifest md5 ${_dir} ${_manifest}) == 404ded59fd3628453e8b11c052cf1c72 ]]"
  bes_assert "[[ $(bes_checksum_manifest sha1 ${_dir} ${_manifest}) == c7e02b7e5010d15723d7bf3daae0a6829bcead5e ]]"
  bes_assert "[[ $(bes_checksum_manifest sha256 ${_dir} ${_manifest}) == 1dfa06817a2e5d9d60f28ae131f6784f5fd9b3beae4d23051b9a9cb487889e4d ]]"
  bes_assert "[[ $(bes_checksum_manifest sha512 ${_dir} ${_manifest}) == 6f6957b4818efd8d22554555f6b23ef016cf43faa68f6bb0a96afd617cf9d82be19deb9e34746ac5ddadb5395296854c40bfe0c2965a81cb1a2cd527e9f0af4d ]]"
  rm -rf ${_tmp}
}

function test_bes_debug_message_debug_is_false()
{
  export _BES_SCRIPT_NAME=myscript
  local actual=$(bes_debug_message foo)
  bes_assert "[[ x == x${actual} ]]"
  unset _BES_SCRIPT_NAME
}

function test_bes_debug_message_debug_is_true()
{
  export _BES_SCRIPT_NAME=myscript
  export BES_DEBUG=1
  local actual=$(bes_debug_message foo | tr ' ' '_' | tr '(' '_' | tr ')' '_')
  local expected="myscript_$$_:_foo"
  bes_assert "[[ ${expected} == ${actual} ]]"
  unset _BES_SCRIPT_NAME BES_DEBUG
}

function test_bes_debug_message_log_file_debug_is_true()
{
  local _tmp=/tmp/test_bes_debug_message_$$.log
  export BES_LOG_FILE=${_tmp}
  export BES_DEBUG=1
  export _BES_SCRIPT_NAME=myscript
  bes_debug_message foo
  local actual=$(cat ${_tmp} | tr ' ' '_' | tr '(' '_'| tr ')' '_')
  local expected="myscript_$$_:_foo"
  bes_assert "[[ ${expected} == ${actual} ]]"
  rm -f ${_tmp}
  unset BES_LOG_FILE BES_DEBUG _BES_SCRIPT_NAME
}

function test_bes_debug_message_log_file_debug_is_false()
{
  local _tmp=/tmp/test_bes_debug_message_$$.log
  export BES_LOG_FILE=${_tmp}
  touch ${BES_LOG_FILE}
  export _BES_SCRIPT_NAME=myscript
  bes_debug_message foo
  local actual=$(cat ${_tmp} | tr ' ' '_' | tr '(' '_'| tr ')' '_')
  bes_assert "[[ x == x${actual} ]]"
  rm -f ${_tmp}
  unset BES_LOG_FILE BES_DEBUG _BES_SCRIPT_NAME
}

function test_bes_function_exists()
{
  function _foo() ( true )
  bes_assert "[[ $(bes_testing_call_function bes_function_exists nothere) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_function_exists _foo) == 0 ]]"
}

function test_bes_function_invoke()
{
  function _call_bes_function_invoke() ( output=$(bes_function_invoke "$@"); rv=$?; echo ${output}:${rv} )
  function _print() ( echo print:$@ )
  function _foo() ( echo foo )
  function _bar() ( echo bar )
  bes_assert "[[ $(_call_bes_function_invoke nothere) == :1 ]]"
  bes_assert "[[ $(_call_bes_function_invoke _foo) == foo:0 ]]"
  bes_assert "[[ $(_call_bes_function_invoke _bar) == bar:0 ]]"
  bes_assert "[[ $(_call_bes_function_invoke _print abc ) == print:abc:0 ]]"
}

function test_bes_function_invoke_if()
{
  function _call_bes_function_invoke_if() ( output=$(bes_function_invoke_if "$@"); rv=$?; echo ${output}:${rv} )
  function _print() ( echo print:$@ )
  function _foo() ( echo foo )
  function _bar() ( echo bar )
  bes_assert "[[ $(_call_bes_function_invoke_if nothere) == :0 ]]"
  bes_assert "[[ $(_call_bes_function_invoke_if _foo) == foo:0 ]]"
  bes_assert "[[ $(_call_bes_function_invoke_if _bar) == bar:0 ]]"
  bes_assert "[[ $(_call_bes_function_invoke_if _print abc ) == print:abc:0 ]]"
}

function test_bes_has_program()
{
  bes_assert "[[ $(bes_testing_call_function bes_has_program bash) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_has_program notthere) == 1 ]]"
  #bes_assert "[[ $(bes_testing_call_function bes_has_program curl) == 0 ]]"
  #bes_assert "[[ $(bes_testing_call_function bes_has_program wget) == 1 ]]"
}

function test_bes_find_program()
{
  local _tmp=/tmp/test_bes_find_program_$$
  mkdir -p ${_tmp}
  printf "#!/bin/bash\necho foo\n" > ${_tmp}/foo.sh ; chmod 755 ${_tmp}/foo.sh
  printf "#!/bin/bash\necho bar\n" > ${_tmp}/bar.sh ; chmod 755 ${_tmp}/bar.sh
  ( PATH=${_tmp}:${PATH} ; bes_assert "[[ $(bes_find_program FOO foo.sh) == foo.sh ]]" )
  ( PATH=${_tmp}:${PATH} FOO=bar.sh ; bes_assert "[[ $(bes_find_program FOO foo.sh) == bar.sh ]]" )
  ( PATH=${_tmp}:${PATH} FOO=${_tmp}/foo.sh ; bes_assert "[[ $(bes_find_program FOO foo.sh) == ${_tmp}/foo.sh ]]" )
  ( PATH=${_tmp}:${PATH} ; bes_assert "[[ $(bes_find_program FOO baz.sh foo.sh) == foo.sh ]]" )
  ( PATH=${_tmp}:${PATH} ; bes_assert "[[ $(bes_testing_call_function bes_find_program FOO notfound.sh) == 1 ]]" )
  rm -rf ${_tmp}
}

function test_bes_abs_dir()
{
  local _tmp_parent=/tmp/parent/test_bes_abs_dir_$$
  local _tmp=${_tmp_parent}/cwd
  mkdir -p ${_tmp}
  bes_assert "[[ $(bes_abs_dir ${_tmp}) == ${_tmp} ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_dir .) == ${_tmp} ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_dir $(pwd)) == ${_tmp} ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_dir foo) == ${_tmp}/foo ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_dir foo/bar) == ${_tmp}/foo/bar ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_dir ../foo) == ${_tmp_parent}/foo ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_dir ..) == ${_tmp_parent} ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_dir foo/bar/..) == ${_tmp}/foo ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_dir foo/../bar) == ${_tmp}/bar ]]"
  rm -rf ${_tmp}
}

function test_bes_abs_file()
{
  local _tmp_parent=/tmp/foo/test_bes_abs_file_$$
  local _tmp=${_tmp_parent}/cwd
  mkdir -p ${_tmp}
  bes_assert "[[ $(bes_abs_file ${_tmp}/foo) == ${_tmp}/foo ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_file foo) == ${_tmp}/foo ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_file $(pwd)/foo) == ${_tmp}/foo ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_file foo/bar) == ${_tmp}/foo/bar ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_file ../foo) == ${_tmp_parent}/foo ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_file foo/bar/../baz) == ${_tmp}/foo/baz ]]"
  bes_assert "[[ $(cd ${_tmp} && bes_abs_file foo/../bar) == ${_tmp}/bar ]]"
  rm -rf ${_tmp}
}

function test_bes_file_extension()
{
  bes_assert "[ $(bes_file_extension foo.png) = png ]"
  bes_assert "[ $(bes_file_extension foo.tar.gz) = gz ]"
  bes_assert "[ $(bes_file_extension foo) = foo ]"
}

function test_bes_str_split()
{
  bes_assert "[ $(bes_str_split a:b:c : | tr ' ' '_') = 'a_b_c' ]"
  bes_assert "[ $(bes_str_split a\ :b:c : | tr ' ' '_') = 'a__b_c' ]"
}

function test_bes_str_is_integer()
{
  bes_assert "[[ $(bes_testing_call_function bes_str_is_integer 0 ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_is_integer 1 ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_is_integer foo ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_is_integer 1.0 ) == 1 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_is_integer 1a ) == 1 ]]"
}

function test_bes_str_starts_with()
{
  bes_assert "[[ $(bes_testing_call_function bes_str_starts_with foo/bar foo ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_starts_with foo/bar foo/ ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_starts_with foo/bar foo/bar ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_starts_with foo/bar f ) == 0 ]]"
  bes_assert "[[ $(bes_testing_call_function bes_str_starts_with foo/bar food ) == 1 ]]"
}

function test_bes_str_remove_head()
{
  bes_assert "[ $(bes_str_remove_head /rel/fruit/1.2.3 /rel/fruit/) = 1.2.3 ]"
  bes_assert "[ $(bes_str_remove_head /rel/fruit/1.2.3 /rel/fruit) = /1.2.3 ]"
  bes_assert "[ $(bes_str_remove_head /rel/fruit/1.2.3 /rel/cheese) = /rel/fruit/1.2.3 ]"
  bes_assert "[ $(bes_str_remove_head /rel/fruit/1.2.3 '') = /rel/fruit/1.2.3 ]"
  bes_assert "[ $(bes_str_remove_head /rel/fruit/1.2.3 /rel/fruit/1.2.3) =  ]"
}

function test_bes_str_remove_tail()
{
  bes_assert "[ $(bes_str_remove_tail /rel/fruit/1.2.3 1.2.3) = /rel/fruit/ ]"
  bes_assert "[ $(bes_str_remove_tail /rel/fruit/1.2.3 1.2.3.4) = /rel/fruit/1.2.3 ]"
  bes_assert "[ $(bes_str_remove_tail /rel/fruit/1.2.3 '') = /rel/fruit/1.2.3 ]"
  bes_assert "[ $(bes_str_remove_tail /rel/fruit/1.2.3 /rel/fruit/1.2.3) =  ]"
}

bes_testing_run_unit_tests
