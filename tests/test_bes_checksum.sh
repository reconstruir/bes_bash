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
bes_import "bes_var.bash"
bes_import "bes_log.bash"
bes_import "bes_system.bash"
bes_import "bes_checksum.bash"
bes_import "bes_testing.bash"

#source "$(_test_this_dir)"/../bash/bes_shell/bes_shell.bash # for bes_sytem

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

bes_testing_run_unit_tests
