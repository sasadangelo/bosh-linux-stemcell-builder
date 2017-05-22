#!/usr/bin/env bash

set -eux

source pipeline-src/ci/tasks/utils.sh

check_param BUILD_VERSION
check_param SL_VM_PREFIX
check_param SL_USERNAME
check_param SL_API_KEY
check_param SL_DATACENTER
check_param SL_VLAN_PUBLIC
check_param SL_VLAN_PRIVATE
SL_VM_PREFIX=${SL_VM_PREFIX}-${BUILD_VERSION}

tar -zxvf director-state/director-state-${BUILD_VERSION}.tgz -C director-state/
cat director-state/director-hosts >> /etc/hosts

tar -xvf compiled-release/compiled-release-allinone-${BUILD_VERSION}.tgz
rm -rf compiled-release/compiled-release-allinone-${BUILD_VERSION}.tgz


BOSH_CLI="$(pwd)/$(echo bosh-cli/bosh-cli-*)"
chmod +x ${BOSH_CLI}

echo "Trying to set target to director: `cat director-state/director-hosts`"

$BOSH_CLI  -e $(cat director-state/director-hosts |awk '{print $2}') --ca-cert <($BOSH_CLI int director-state/credentials.yml --path /DIRECTOR_SSL/ca ) alias-env bosh-env

echo "Trying to login to director..."

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(${BOSH_CLI} int director-state/credentials.yml --path /DI_ADMIN_PASSWORD)

$BOSH_CLI -e bosh-env login

for release_file in compiled-release/*.tgz; do
  echo "Upload release $release_file"
  $BOSH_CLI -e bosh-env upload-release compiled-release/$release_file
done

echo "Deploy release by using compiled-deploy/compiled-deploy-${BUILD_VERSION}.yml"
deployment_name=compiled-release
$BOSH_CLI -e bosh-env -d ${deployment_name} deploy compiled-deploy/compiled-deploy-${BUILD_VERSION}.yml -n