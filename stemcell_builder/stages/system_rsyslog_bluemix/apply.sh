#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

echo "echo the version of rsyslog before upgrade"
run_in_chroot $chroot "rsyslogd -v"

curl -L -o $chroot/tmp/libfastjson4_0.99.8-2_amd64.deb "https://s3.amazonaws.com/bosh-softlayer-artifacts/packages/libfastjson4_0.99.8-2_amd64.deb"
curl -L -o $chroot/tmp/rsyslog_8.34.0-0adiscon2xenial1_amd64.deb "https://s3.amazonaws.com/bosh-softlayer-artifacts/packages/rsyslog_8.34.0-0adiscon2xenial1_amd64.deb"

run_in_chroot $chroot "
cd /tmp

dpkg -i --force-confnew libfastjson4_0.99.8-2_amd64.deb \
   rsyslog_8.34.0-0adiscon2xenial1_amd64.deb

rm *.deb
"

sed -i "s/install ok half-configured/install ok installed/g" $chroot/var/lib/dpkg/status
sed -i "/Config-Version: 8.22.0-0adiscon1trusty1/d" $chroot/var/lib/dpkg/status

echo "echo the version of rsyslog after upgrade"
run_in_chroot $chroot "
#ln -sf /lib/init/upstart-job /etc/init.d/rsyslog
#update-rc.d rsyslog defaults
rsyslogd -v
"