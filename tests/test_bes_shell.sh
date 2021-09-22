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

source "$(_test_bes_shell_this_dir)"/../bash/bes_shell/bes_shell.bash
bes_import "bes_testing.bash"

function test_bes_source_file()
{
  local _pid=$$
  local _tmp="/tmp/test_bes_source_dir_${_pid}"
  mkdir -p "${_tmp}"
  echo "FOO=foo_${_pid}" > "$_tmp/1.sh"
  (
    bes_source_file "$_tmp/1.sh"
    bes_assert "[ ${FOO} = foo_${_pid} ]"
  )
  rm -rf ${_tmp}
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

function test_bes_filename_extension()
{
  bes_assert "[ $(bes_filename_extension foo.png) = png ]"
  bes_assert "[ $(bes_filename_extension foo.tar.gz) = gz ]"
  bes_assert "[ $(bes_filename_extension foo) = foo ]"
}


function _make_test_program()
{
  local _where="${1}"
  local _name="${2}"
  local _program="${_where}/${_name}"
  local _dirname="$(dirname "${_program}")"
  mkdir -p "${_dirname}"
  cat > ${_program} << EOF
#!/bin/sh
echo ${_name}
EOF
  chmod 755 ${_program}
  echo "${_program}"
  return 0
}

function test__bes_which_one_program()
{
  function _call__bes_which_one_program()
  {
    local _value="$(_bes_which_one_program ${1+"$@"} | "${_BES_TR_EXE}" ' ' '_')"
    _bes_which_one_program ${1+"$@"} >& /dev/null
    local _rv=$?
    echo ${_rv}:"${_value}"
    return 0
  }
  
  local _tmp=/tmp/test__bes_which_one_program_$$
  mkdir -p ${_tmp}
  local _p1=${_tmp}/p1
  local _p2=${_tmp}/p2

  local _program_one=$(_make_test_program "${_p1}" one)
  local _program_two=$(_make_test_program "${_p2}" two)

  local _path="${_p1}":"${_p2}"
  
  bes_assert "[[ $( PATH="${_path}" _call__bes_which_one_program one false) == 0:${_program_one} ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which_one_program notthere false) == 1: ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which_one_program two false) == 0:${_program_two} ]]"

  rm -rf ${_tmp}
}

function test__bes_which()
{
  function _call__bes_which()
  {
    local _value="$(_bes_which ${1+"$@"} | "${_BES_TR_EXE}" '\n' '@' | "${_BES_TR_EXE}" ' ' '_')"
    _bes_which ${1+"$@"} >& /dev/null
    local _rv=$?
    echo ${_rv}:"${_value}"
    return 0
  }
  
  local _tmp=/tmp/test__bes_which_$$
  mkdir -p ${_tmp}
  local _p1=${_tmp}/p1
  local _p2=${_tmp}/p2
  local _p3=${_tmp}/p3

  local _program1=$(_make_test_program "${_p1}" one)
  local _program2=$(_make_test_program "${_p2}" two)
  local _program3=$(_make_test_program "${_p3}" two)

  local _path="${_p1}":"${_p2}":"${_p3}"

  
  bes_assert "[[ $( PATH="${_path}" _call__bes_which one) == 0:${_program1}@ ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which notthere) == 1: ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which two) == 0:${_program2}@ ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which one two) == 0:${_program1}@${_program2}@ ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which two one) == 0:${_program2}@${_program1}@ ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which one notthere) == 1:${_program1}@ ]]"

  bes_assert "[[ $( PATH="${_path}" _call__bes_which -s one) == 0: ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which -s notthere) == 1: ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which -s two) == 0: ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which -s one two) == 0: ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which -s two one) == 0: ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which -s one notthere) == 1: ]]"

  bes_assert "[[ $( PATH="${_path}" _call__bes_which -a two) == 0:${_program2}@${_program3}@ ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which -a one two) == 0:${_program1}@${_program2}@${_program3}@ ]]"

  bes_assert "[[ $( PATH="${_path}" _call__bes_which -a -s two) == 0: ]]"
  bes_assert "[[ $( PATH="${_path}" _call__bes_which -a -s one two) == 0: ]]"
  
  rm -rf ${_tmp}
}

bes_testing_run_unit_tests
