#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

# comment out "-e 2" to not make the auditd configuration immutable
sed -i "s/^-e 2/#-e 2/g" $chroot/etc/audit/rules.d/audit.rules
echo "echo /etc/audit/rules.d/audit.rules"
chroot $chroot cat /etc/audit/rules.d/audit.rules

# faillog workarounf for xenial
if [[ "${DISTRIB_CODENAME}" == 'xenial' ]]; then
  touch $chroot/var/log/faillog
  chmod 600 $chroot/var/log/faillog
fi