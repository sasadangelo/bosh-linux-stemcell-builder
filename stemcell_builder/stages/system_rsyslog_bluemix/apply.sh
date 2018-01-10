#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

echo "echo the version of rsyslog before upgrade"
run_in_chroot $chroot "rsyslogd -v"

run_in_chroot $chroot "
wget https://s3.amazonaws.com/bosh-softlayer-tmp/librelp0_1.2.14-0adiscon1trusty1_amd64.deb
wget https://s3.amazonaws.com/bosh-softlayer-tmp/libfastjson4_0.99.4-adiscon1trusty1_amd64.deb
wget https://s3.amazonaws.com/bosh-softlayer-tmp/libgcrypt11_1.5.3-2ubuntu4.5_amd64.deb
wget https://s3.amazonaws.com/bosh-softlayer-tmp/liblogging-stdlog1_1.0.5-0adiscon1trusty1_amd64.deb
wget https://s3.amazonaws.com/bosh-softlayer-tmp/rsyslog_8.29.0-0adiscon3trusty1_amd64.deb
wget https://s3.amazonaws.com/bosh-softlayer-tmp/rsyslog-gnutls_8.29.0-0adiscon3trusty1_amd64.deb
wget https://s3.amazonaws.com/bosh-softlayer-tmp/rsyslog-mmjsonparse_8.29.0-0adiscon3trusty1_amd64.deb
wget https://s3.amazonaws.com/bosh-softlayer-tmp/rsyslog-relp_8.29.0-0adiscon3trusty1_amd64.deb

wget https://s3.amazonaws.com/bosh-softlayer-tmp/libnl-route-3-200_3.2.21-1ubuntu4.1_amd64.deb
wget https://s3.amazonaws.com/bosh-softlayer-tmp/ldap-utils_2.4.31-1%2Bnmu2ubuntu8.4_amd64.deb

dpkg -i libfastjson4_0.99.4-adiscon1trusty1_amd64.deb \
   libgcrypt11_1.5.3-2ubuntu4.5_amd64.deb \
   liblogging-stdlog1_1.0.5-0adiscon1trusty1_amd64.deb \
   rsyslog_8.29.0-0adiscon3trusty1_amd64.deb
dpkg -i librelp0_1.2.14-0adiscon1trusty1_amd64.deb \
   rsyslog-gnutls_8.29.0-0adiscon3trusty1_amd64.deb \
   rsyslog-mmjsonparse_8.29.0-0adiscon3trusty1_amd64.deb \
   rsyslog-relp_8.29.0-0adiscon3trusty1_amd64.deb \
   libnl-route-3-200_3.2.21-1ubuntu4.1_amd64.deb \
   ldap-utils_2.4.31-1+nmu2ubuntu8.4_amd64.deb

rm *.deb
"

sed -i "s/install ok half-configured/install ok installed/g" $chroot/var/lib/dpkg/status
sed -i "/Config-Version: 8.22.0-0adiscon1trusty1/d" $chroot/var/lib/dpkg/status

echo "echo the version of rsyslog after upgrade"
run_in_chroot $chroot "
ln -sf /lib/init/upstart-job /etc/init.d/rsyslog
update-rc.d rsyslog defaults
rsyslogd -v
"