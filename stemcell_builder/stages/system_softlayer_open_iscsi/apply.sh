#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash


pkg_mgr install open-iscsi

# append 'service iscsid restart' in /etc/init.d/open-iscsi stop
if [ -f $chroot/etc/debian_version ] # Ubuntu
then
  if [ ${DISTRIB_CODENAME} == 'xenial' ]; then
    if [ -f $chroot/etc/init.d/open-iscsi ]
    then
      sed -i '
/^restart() {$/ {
n
a\\tservice iscsid restart
}' $chroot/etc/init.d/open-iscsi
    fi
  fi
fi
