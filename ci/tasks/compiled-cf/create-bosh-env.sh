#!/usr/bin/env bash
set -ex

touch director-state/director-state-1.txt
echo "Hello Yes!" > director-state/director-state-1.txt
mkdir -p bosh/publish/235018
echo $FILE_W3_BOSH_PEM > bosh/bosh.pem
cp director-state/director-state-1.txt bosh/publish/235018/
cd bosh
scp -i ./bosh.pem -r publish/235018/director-state/director-state-1.txt bosh@file.w3.bluemix.net:~/repo
