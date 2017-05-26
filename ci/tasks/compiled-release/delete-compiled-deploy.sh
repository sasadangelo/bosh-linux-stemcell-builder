#!/usr/bin/env bash

set -eux

source pipeline-src/ci/tasks/utils.sh

BUILD_VERSION=`cat version/number | cut -d "." -f 3`

tar -zxvf director-state/director-state-${BUILD_VERSION}.tgz -C director-state/
cat director-state/director-hosts >> /etc/hosts

BOSH_CLI="$(pwd)/$(echo bosh-cli/bosh-cli-*)"
chmod +x ${BOSH_CLI}

echo "Trying to set target to director: `cat director-state/director-hosts`"

$BOSH_CLI  -e $(cat director-state/director-hosts |awk '{print $2}') --ca-cert <($BOSH_CLI int director-state/credentials.yml --path /DIRECTOR_SSL/ca ) alias-env bosh-env

echo "Trying to login to director..."

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(${BOSH_CLI} int director-state/credentials.yml --path /DI_ADMIN_PASSWORD)

$BOSH_CLI -e bosh-env login

deployment_name=compiled-release
echo "Delete deployment $deployment_name"
$BOSH_CLI -e bosh-env delete-deployment -d ${deployment_name} -n
$BOSH_CLI -e bosh-env deployments

# release_string=`cat compiled-deploy/compiled-deploy-${BUILD_VERSION}.yml | grep -Po '(?<=- location: ).*' | sed "s/.*releases\///g" | sed "s/\/.*//g"`
# Check which release is installed directly
release_string=`$BOSH_CLI -e bosh-env releases | awk -F ' ' '{print $1}'`

if [ "$release_string" != "" ]; then
release_array=($release_string)
for release in "${release_array[@]}"
do
    echo "Delete release $release"
    $BOSH_CLI -e bosh-env delete-release $release -n
done
fi

$BOSH_CLI -e bosh-env releases
