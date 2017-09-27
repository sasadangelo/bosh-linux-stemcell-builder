#!/bin/bash

set -e
set -u

export VERSION=$( cat version/number | sed 's/\.0$//;s/\.0$//' )
cp stemcell/*.tgz light-softlayer-stemcell-prod/

fileUrl=https://s3.amazonaws.com/${CANDIDATE_BUCKET_NAME}/light-bosh-stemcell-${VERSION}-bluemix-xen-ubuntu-trusty-go_agent.tgz
checksum=`curl -L ${fileUrl} | sha1sum | cut -d " " -f 1`
echo -e "Sha1 hashcode -> $checksum"

echo "stable-${VERSION}" > version-tag/tag

echo "Done"
