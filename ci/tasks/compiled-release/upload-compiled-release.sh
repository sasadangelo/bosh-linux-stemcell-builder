#!/usr/bin/env bash

set -eux

source pipeline-src/ci/tasks/utils.sh

check_param cf_release
check_param cf_release_version
check_param FILE_W3_BOSH_PEM

BUILD_VERSION=`cat version/version | cut -d "." -f 3`

mkdir -p bosh/publish/compiled
#echo "FILE_W3_BOSH_PEM: ${FILE_W3_BOSH_PEM}"
echo ${FILE_W3_BOSH_PEM} > bosh/bosh.pem
mv compiled-release/cf-compiled-release-allinone-${cf_release_version}-${BUILD_VERSION}.tgz bosh/publish/compiled/

cd bosh
sed -i "s/-----BEGIN RSA PRIVATE KEY----- //g" bosh.pem
sed -i "s/ -----END RSA PRIVATE KEY-----//g" bosh.pem
sed -i "s/ /\n/g" bosh.pem
sed -i "1i\-----BEGIN RSA PRIVATE KEY-----" bosh.pem
sed -i "\$a-----END RSA PRIVATE KEY-----" bosh.pem
cat bosh.pem
chmod 400 bosh.pem
scp -i bosh.pem -o "StrictHostKeyChecking no" -r publish/compiled/ bosh@file.w3.bluemix.net:~/repo

echo "scp cf-compiled-release-allinone-${cf_release_version}-${BUILD_VERSION}.tg file to file w3:"
echo "http://file.w3.bluemix.net/releases/bosh/compiled/cf-compiled-release-allinone-${cf_release_version}-${BUILD_VERSION}.tg"