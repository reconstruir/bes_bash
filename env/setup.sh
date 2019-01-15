if [ -n "$_BES_TRACE" ]; then echo "bes_shell_setup.sh begin"; fi

_bes_shell_dev_root()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
  return 0
}

_BES_DEV_ROOT=$(_bes_shell_dev_root)

source ${_BES_DEV_ROOT}/bes_shell/bes_shell.sh

bes_shell_dev()
{
  bes_shell_setup ${_BES_DEV_ROOT} ${1+"$@"}
  return 0
}

bes_shell_undev()
{
  bes_shell_unsetup ${_BES_DEV_ROOT}
  return 0
}

if [ -n "$_BES_TRACE" ]; then echo "bes_shell_setup.sh end"; fi
