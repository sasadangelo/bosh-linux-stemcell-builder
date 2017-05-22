#!/usr/bin/env bash
set -ex

source pipeline-src/ci/tasks/utils.sh

check_param BUILD_VERSION
check_param SL_VM_PREFIX
check_param SL_USERNAME
check_param SL_API_KEY
check_param SL_DATACENTER
check_param SL_VLAN_PUBLIC
check_param SL_VLAN_PRIVATE
SL_VM_PREFIX=${SL_VM_PREFIX}-${BUILD_VERSION}

deployment_dir="${PWD}/deployment"
mkdir -p $deployment_dir

SL_VM_DOMAIN=${SL_VM_PREFIX}.softlayer.com

STEMCELL_NAME="$(ls stemcell|grep tgz)"
ORG_STEMCELL_NAME="light-bosh-stemcell-3363.12.3-bluemix-xen-ubuntu-trusty-go_agent.tgz"
cp pipeline-src/ci/tasks/templates/bosh-template.yml bosh-template.yml
sed -i 's/'"$ORG_STEMCELL_NAME"'/'"$STEMCELL_NAME"'/g' bosh-template.yml

BOSH_CLI="$(pwd)/$(echo bosh-cli/bosh-cli-*)"
chmod +x ${BOSH_CLI}

  function finish {
    echo "Final state of director deployment:"
    echo "====================================================================="
    cat bosh-template-state.json
    echo "====================================================================="
    echo "Director:"
    echo "====================================================================="
    cat /etc/hosts | grep "$SL_VM_DOMAIN" | tee ${deployment_dir}/director-hosts
    echo "====================================================================="
    echo "Saving config..."
    cp $BOSH_CLI bosh-template.yml bosh-template-state.json ${deployment_dir}/
    pushd ${deployment_dir}
      tar -zcvf  /tmp/director-state-${BUILD_VERSION}.tgz ./ >/dev/null 2>&1
    popd
    mv /tmp/director-state-${BUILD_VERSION}.tgz director-state/

    echo "You can download the director-state-${BUILD_VERSION}.tgz file by using this url after finish:"
    echo "https://s3-api.us-geo.objectstorage.softlayer.net/bosh-softlayer-compiled-cf-release/director-state/director-state-${BUILD_VERSION}.tgz"
  }

trap finish ERR

echo "Using bosh-cli $($BOSH_CLI -v)"
echo "Deploying director..."

$BOSH_CLI create-env bosh-template.yml \
                      --state=bosh-template-state.json \
                      --vars-store ${deployment_dir}/credentials.yml \
                      -v SL_VM_PREFIX=${SL_VM_PREFIX} \
                      -v SL_VM_DOMAIN=${SL_VM_DOMAIN} \
                      -v SL_USERNAME=${SL_USERNAME} \
                      -v SL_API_KEY=${SL_API_KEY} \
                      -v SL_DATACENTER=${SL_DATACENTER} \
                      -v SL_VLAN_PUBLIC=${SL_VLAN_PUBLIC} \
                      -v SL_VLAN_PRIVATE=${SL_VLAN_PRIVATE}

echo "Trying to set target to director..."

$BOSH_CLI  -e ${SL_VM_DOMAIN} --ca-cert <($BOSH_CLI int ${deployment_dir}/credentials.yml --path /DIRECTOR_SSL/ca) alias-env bosh-env

echo "Trying to login to director..."

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(${BOSH_CLI} int ${deployment_dir}/credentials.yml --path /DI_ADMIN_PASSWORD)

$BOSH_CLI -e bosh-env login

trap - ERR

finish
