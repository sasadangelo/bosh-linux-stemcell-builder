#!/usr/bin/env bash
set -ex

source pipeline-src/ci/tasks/utils.sh

check_param FILE_W3_BOSH_PEM

echo "FILE_W3_BOSH_PEM: $FILE_W3_BOSH_PEM"
touch director-state/director-state-1.txt
echo "Hello `date`!" > director-state/director-state-1.txt
mkdir -p bosh/publish/235019
echo $FILE_W3_BOSH_PEM > bosh/bosh.pem
cp director-state/director-state-1.txt bosh/publish/235019/

cd bosh
scp -i bosh.pem -o "StrictHostKeyChecking no" -r publish/235019/director-state-1.txt bosh@file.w3.bluemix.net:~/repo
