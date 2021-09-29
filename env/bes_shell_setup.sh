if [ -n "$_BES_TRACE" ]; then echo "bes_shell_setup.sh begin"; fi

_bes_shell_dev_root()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
  return 0
}

bes_shell_dev()
{
  local _bes_shell_root_dir="$(_bes_shell_dev_root)"
  source "${_bes_shell_root_di../../bash/bes_bash/bes_basic.bash"
  source "${_bes_shell_root_dir}/bash/bes_shell/bes_dev.bash"
  local _bes_root_dir="$(_bes_dev_root)"
  bes_dev_setup "${_bes_root_dir}" \
               --light \
               --no-set-python-path
  local _virtual_env_setup="${_bes_shell_root_dir}/env/bes_shell_venv_activate.bash"
  bes_dev_setup "${_bes_shell_root_dir}" \
               --light \
               --set-title \
               --change-dir \
               --no-set-python-path \
               ${1+"$@"}
  return $?
}

bes_shell_undev()
{
  local _bes_shell_root_dir="$(_bes_shell_dev_root)"
  source "${_bes_shell_root_di../../bash/bes_bash/bes_basic.bash"
  source "${_bes_shell_root_dir}/bash/bes_shell/bes_dev.bash"
  bes_dev_unsetup "${_bes_shell_root_dir}"
  return $?
}

if [ -n "$_BES_TRACE" ]; then echo "bes_shell_setup.sh end"; fi
