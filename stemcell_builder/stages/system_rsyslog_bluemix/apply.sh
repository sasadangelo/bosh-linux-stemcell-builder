#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

echo "echo the version of rsyslog before upgrade"
run_in_chroot $chroot "rsyslogd -v"

run_in_chroot $chroot "
add-apt-repository -y ppa:adiscon/v8-stable
apt-get update
apt-get -y install rsyslog
wget https://s3.amazonaws.com/bosh-softlayer-tmp/libnl-route-3-200_3.2.21-1ubuntu4.1_amd64.deb
wget https://s3.amazonaws.com/bosh-softlayer-tmp/ldap-utils_2.4.31-1%2Bnmu2ubuntu8.4_amd64.deb

dpkg -i libnl-route-3-200_3.2.21-1ubuntu4.1_amd64.deb \
   ldap-utils_2.4.31-1+nmu2ubuntu8.4_amd64.deb

rm *.deb
"

sed -i "s/install ok half-configured/install ok installed/g" $chroot/var/lib/dpkg/status
sed -i "/Config-Version: 8.22.0-0adiscon1trusty1/d" $chroot/var/lib/dpkg/status

echo "echo the version of rsyslog after upgrade"
run_in_chroot $chroot "rsyslogd -v"