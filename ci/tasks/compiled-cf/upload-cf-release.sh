#!/usr/bin/env bash

set -eux

source pipeline-src/ci/tasks/utils.sh

check_param cf_release
check_param BUILD_VERSION
check_param FILE_W3_BOSH_PEM

pwd
mkdir -p bosh/publish/${cf_release}
#echo "FILE_W3_BOSH_PEM: ${FILE_W3_BOSH_PEM}"
echo ${FILE_W3_BOSH_PEM} > bosh/bosh.pem
mv compiled-release/cf-compiled-release-${BUILD_VERSION}.tgz bosh/publish/${cf_release}/

cd bosh
chmod 400 bosh.pem
scp -i bosh.pem -o "StrictHostKeyChecking no" -r publish/${cf_release}/cf-compiled-release-${BUILD_VERSION}.tgz bosh@file.w3.bluemix.net:~/repo

echo "scp cf-compiled-release-${BUILD_VERSION}.tgz file to file w3:"
ehco "http://file.w3.bluemix.net/releases/bosh/${cf_release}/cf-compiled-release-${BUILD_VERSION}.tgz"