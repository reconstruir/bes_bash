#!/bin/bash

function _test_bes_system_this_dir()
{
  local _this_file
  local _test_bes_system_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_system_this_dir="${_this_file%/*}"
  if [ "${_test_bes_system_this_dir}" == "${_this_file}" ]; then
    _test_bes_system_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_system_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_system_this_dir)"/../bash/bes_shell/bes_shell.bash
bes_import "bes_testing.bash"
bes_import "bes_system.bash"

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
