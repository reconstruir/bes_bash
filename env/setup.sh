_bes_shell_dev_root()
{
  echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
  return 0
}

bes_shell_dev()
{
  bes_dev no
  bes_setup $(_bes_shell_dev_root) ${1+"$@"}
  return 0
}

bes_shell_undev()
{
  bes_unsetup $(_bes_shell_dev_root)
  return 0
}
