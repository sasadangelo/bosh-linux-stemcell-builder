#!/usr/bin/env bash

set -eux

source pipeline-src/ci/tasks/utils.sh

check_param cf_release_version
check_param BUILD_VERSION
check_param cf_release
check_param cf_release_version
check_param stemcell_version
check_param FILE_W3_BOSH_PEM

pwd
mkdir -p bosh/publish/${cf_release_version}
#echo "FILE_W3_BOSH_PEM: ${FILE_W3_BOSH_PEM}"
echo ${FILE_W3_BOSH_PEM} > bosh/bosh.pem
mv compiled-release/${cf_release}-${cf_release_version}-ubuntu-trusty-${stemcell_version}-${BUILD_VERSION}.tgz bosh/publish/${cf_release_version}/

cd bosh
sed -i "s/-----BEGIN RSA PRIVATE KEY----- //g" bosh.pem
sed -i "s/ -----END RSA PRIVATE KEY-----//g" bosh.pem
sed -i "s/ /\n/g" bosh.pem
sed -i "1i\-----BEGIN RSA PRIVATE KEY-----" bosh.pem
sed -i "\$a-----END RSA PRIVATE KEY-----" bosh.pem
cat bosh.pem
chmod 400 bosh.pem
scp -i bosh.pem -o "StrictHostKeyChecking no" -r publish/${cf_release_version}/ bosh@file.w3.bluemix.net:~/repo

echo "scp ${cf_release}-${cf_release_version}-ubuntu-trusty-${stemcell_version}-${BUILD_VERSION}.tgz file to file w3:"
echo "http://file.w3.bluemix.net/releases/bosh/${cf_release_version}/${cf_release}-${cf_release_version}-ubuntu-trusty-${stemcell_version}-${BUILD_VERSION}.tgz"