#!/bin/bash

function _test_bes_pipenv_this_dir()
{
  local _this_file
  local _test_bes_pipenv_this_dir
  _this_file="$(command readlink "${BASH_SOURCE}" )" || _this_file="${BASH_SOURCE}"
  _test_bes_pipenv_this_dir="${_this_file%/*}"
  if [ "${_test_bes_pipenv_this_dir}" == "${_this_file}" ]; then
    _test_bes_pipenv_this_dir=.
  fi
  echo $(command cd -P "${_test_bes_pipenv_this_dir}" > /dev/null && command pwd -P )
  return 0
}

source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/bes_shell.sh
source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/bes_python.sh
source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/bes_download.sh
source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/bes_pip.sh
source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/bes_pipenv.sh
source "$(_test_bes_pipenv_this_dir)"/../bash/bes_shell/_bes_python_testing.sh

function test_bes_pipenv_ensure()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "bes_pipenv_ensure: skipping because no builtin python found"
    return 0
  fi
  local _tmp=/tmp/test_bes_pipenv_ensure_$$

  bes_assert "[[ $(bes_testing_call_function bes_pipenv_has_pipenv ${_builtin_python} ${_tmp} ) == 1 ]]"
  
  bes_pipenv_ensure "${_builtin_python}" "${_tmp}" 20.2.2 2020.8.13
  local _ensure_rv=$?
  bes_assert "[[ ${_ensure_rv} == 0 ]]"

  bes_assert "[[ $(bes_testing_call_function bes_pipenv_has_pipenv ${_builtin_python} ${_tmp} ) == 0 ]]"
  
  rm -rf ${_tmp}
}

function test_bes_pipenv_version()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "bes_pipenv_ensure: skipping because no builtin python found"
    return 0
  fi
  local _tmp=/tmp/test_bes_pipenv_version_$$

  bes_pipenv_ensure "${_builtin_python}" "${_tmp}" 20.2.2 2020.8.13
  local _pipenv_version=$(bes_pipenv_version ${_builtin_python} ${_tmp})
  bes_assert "[[ ${_pipenv_version} == 2020.8.13 ]]"
  
  rm -rf ${_tmp}
}

function test_bes_pipenv_call()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "bes_pipenv_call: skipping because no builtin python found"
    return 0
  fi

  local _tmp=/tmp/test_bes_pipenv_call_$$

  bes_pipenv_ensure "${_builtin_python}" "${_tmp}" 20.2.2 2020.8.13

  echo TEST1
  bes_pipenv_call "${_builtin_python}" "${_tmp}" --version 
  echo TEST2
  
#  local _pipenv_version=$(bes_pipenv_call "${_builtin_python}" "${_tmp}" --version | awk '{ print $3; }')
#  bes_assert "[[ ${_pipenv_version} == 2020.8.13 ]]"
  
#  rm -rf ${_tmp}
}

function test_bes_pipenv_exe()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "bes_pipenv_call: skipping because no builtin python found"
    return 0
  fi

  local _tmp=/tmp/test_bes_pipenv_exe_$$

  bes_pipenv_ensure "${_builtin_python}" "${_tmp}" 20.2.2 2020.8.13
  local _ensure_rv=$?
  bes_assert "[[ ${_ensure_rv} == 0 ]]"

  local _pipenv_exe=$(bes_pipenv_exe "${_builtin_python}" "${_tmp}")

  bes_assert "[[ $(bes_testing_call_function test -x ${_pipenv_exe}) == 0 ]]"

  rm -rf ${_tmp}
}

function test_bes_pipenv_install_requirements()
{
  local _builtin_python="$(bes_python_find_builtin_python)"
  if [[ ! -x ${_builtin_python} ]]; then
    bes_message "test_bes_pipenv_install_requirements: skipping because no builtin python found"
    return 0
  fi
  local _tmp=/tmp/test_bes_pipenv_install_requirements_$$

  bes_pipenv_ensure "${_builtin_python}" "${_tmp}" 20.2.2 2020.8.13
  local _ensure_rv=$?
  bes_assert "[[ ${_ensure_rv} == 0 ]]"

  local _test_requirements=${_tmp}/test_requirements.txt
  cat > ${_test_requirements} << EOF
asn1crypto==0.24.0
awscli==1.18.62
boto3==1.13.8
botocore==1.16.12
cachetools==3.0.0
certifi==2019.3.9
cffi==1.13.2
chardet==3.0.4
cryptography==2.9.2
docutils==0.15.2
google-api-python-client==1.7.8
google-auth-httplib2==0.0.3
google-auth-oauthlib==0.3.0
google-auth==1.6.1
httplib2==0.17.0
idna==2.6
jmespath==0.9.4
nose==1.3.7
oauthlib==2.0.7
pyasn1-modules==0.2.2
pyasn1==0.4.8
pycparser==2.18
PyJWT==1.6.1
python-dateutil==2.8.1
PyYAML==5.3.1
requests-oauthlib==0.8.0
requests==2.22.0
rsa==3.4.2
s3transfer==0.3.3
six==1.14.0
slackclient==1.3.2
uritemplate==3.0.0
urllib3==1.25.8
EOF

  bes_pipenv_call "${_builtin_python}" "${_tmp}" install -r "${_test_requirements}"

  rm -rf ${_tmp}
}

bes_testing_run_unit_tests
