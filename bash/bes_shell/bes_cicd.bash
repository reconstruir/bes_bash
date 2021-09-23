#-*- coding:utf-8; mode:shell-script; indent-tabs-mode: nil; sh-basic-offset: 2; tab-width: 2 -*-

# Return 0 if currently running under a CICD system
function bes_cicd_running_under_cicd()
{
  # bitbucket,github
  if [[ -n "${CI}" ]]; then
    return 0
  fi
  # jenkins
  if [[ -n "${HUDSON_COOKIE}" ]]; then
    return 0
  fi
  # gitlab
  if [[ -n "${GITLAB_CI}" ]]; then
    return 0
  fi
  return 1
}
