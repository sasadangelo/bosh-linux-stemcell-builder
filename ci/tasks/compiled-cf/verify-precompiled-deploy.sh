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
check_param cf_release
check_param cf_release_version
SL_VM_PREFIX=${SL_VM_PREFIX}-${BUILD_VERSION}

STEMCELL_VERSION=$(cat stemcell/version)

tar -zxvf director-state/director-state-${BUILD_VERSION}.tgz -C director-state/
cat director-state/director-hosts >> /etc/hosts

mv compiled-release/cf-compiled-release-${BUILD_VERSION}.tgz compiled-release/${cf_release}-${cf_release_version}-ubuntu-trusty-${STEMCELL_VERSION}-${BUILD_VERSION}.tgz


BOSH_CLI="$(pwd)/$(echo bosh-cli/bosh-cli-*)"
chmod +x ${BOSH_CLI}

echo "Trying to set target to director: `cat director-state/director-hosts`"

$BOSH_CLI  -e $(cat director-state/director-hosts |awk '{print $2}') --ca-cert <($BOSH_CLI int director-state/credentials.yml --path /DIRECTOR_SSL/ca ) alias-env bosh-env

echo "Trying to login to director..."

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(${BOSH_CLI} int director-state/credentials.yml --path /DI_ADMIN_PASSWORD)

$BOSH_CLI -e bosh-env login

$BOSH_CLI -e bosh-env upload-release compiled-release/${cf_release}-${cf_release_version}-ubuntu-trusty-${STEMCELL_VERSION}-${BUILD_VERSION}.tgz
