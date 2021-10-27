if [ -n "$_BES_TRACE" ]; then echo "bes_bash_setup.sh begin"; fi

_bes_bash_dev_root()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
  return 0
}

bes_bash_dev()
{
  local _bes_bash_root_dir="$(_bes_bash_dev_root)"
  source "${_bes_bash_root_dir}/bash/bes_bash/bes_basic.bash"
  bes_import "bes_dev.bash"
  local _bes_root_dir="$(_bes_dev_root)"
  bes_dev_setup "${_bes_root_dir}" \
               --light \
               --no-set-python-path
  local _virtual_env_setup="${_bes_bash_root_dir}/env/bes_bash_venv_activate.bash"
  bes_dev_setup "${_bes_bash_root_dir}" \
               --light \
               --set-title \
               --change-dir \
               --no-set-python-path \
               ${1+"$@"}
  return $?
}

bes_bash_undev()
{
  local _bes_bash_root_dir="$(_bes_bash_dev_root)"
  source "${_bes_bash_root_dir}/bash/bes_bash/bes_basic.bash"
  bes_import "bes_dev.bash"
  bes_dev_unsetup "${_bes_bash_root_dir}"
  return $?
}

if [ -n "$_BES_TRACE" ]; then echo "bes_bash_setup.sh end"; fi
