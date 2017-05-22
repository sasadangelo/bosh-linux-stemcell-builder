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
check_param stemcell_version
SL_VM_PREFIX=${SL_VM_PREFIX}-${cf_release}-${cf_release_version}-ubuntu-trusty-${stemcell_version}-${BUILD_VERSION}

#
# target/authenticate
#

tar -zxvf director-state/director-state-precompiled-${cf_release}-${cf_release_version}-ubuntu-trusty-${stemcell_version}-${BUILD_VERSION}.tgz -C director-state/
cat director-state/director-hosts >> /etc/hosts

BOSH_CLI="$(pwd)/$(echo bosh-cli/bosh-cli-*)"
chmod +x ${BOSH_CLI}

SL_VM_DOMAIN=${SL_VM_PREFIX}.softlayer.com
cp director-state/bosh-template.yml ./
cp director-state/bosh-template-state.json ./

$BOSH_CLI delete-env bosh-template.yml \
                      --vars-store director-state/credentials.yml \
                      -v SL_VM_PREFIX=${SL_VM_PREFIX} \
                      -v SL_VM_DOMAIN=${SL_VM_DOMAIN} \
                      -v SL_USERNAME=${SL_USERNAME} \
                      -v SL_API_KEY=${SL_API_KEY} \
                      -v SL_DATACENTER=${SL_DATACENTER} \
                      -v SL_VLAN_PUBLIC=${SL_VLAN_PUBLIC} \
                      -v SL_VLAN_PRIVATE=${SL_VLAN_PRIVATE}