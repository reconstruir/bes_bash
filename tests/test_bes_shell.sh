#!/bin/bash

function _test_this_dir()
{
  local _this_file
  local _test_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_this_dir="${_this_file%/*}"
  if [ "${_test_this_dir}" == "${_this_file}" ]; then
    _test_this_dir=.
  fi
  echo $(command cd -P "${_test_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_this_dir)"/../bash/bes_shell/bes_shell.bash
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

bes_testing_run_unit_tests
