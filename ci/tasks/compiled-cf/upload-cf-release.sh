#!/usr/bin/env bash

set -eux

source pipeline-src/ci/tasks/utils.sh

check_param cf_release
check_param FILE_W3_BOSH_PEM

mkdir -p bosh/publish/${cf_release}
echo "FILE_W3_BOSH_PEM: ${FILE_W3_BOSH_PEM}"
echo ${FILE_W3_BOSH_PEM} > bosh/bosh.pem
cp cf-(.*).tgz bosh/publish/${cf_release}/

cd bosh
scp -i bosh.pem -o "StrictHostKeyChecking no" -r publish/${cf_release}/*.tgz bosh@file.w3.bluemix.net:~/repo