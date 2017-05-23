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

tar -zxvf director-state/director-state-${BUILD_VERSION}.tgz -C director-state/
cat director-state/director-hosts >> /etc/hosts

tar -xvf compiled-release/compiled-release-allinone-${BUILD_VERSION}.tgz
rm -rf compiled-release/compiled-release-allinone-${BUILD_VERSION}.tgz


BOSH_CLI="$(pwd)/$(echo bosh-cli/bosh-cli-*)"
chmod +x ${BOSH_CLI}

DIRECTOR=$(cat director-state/director-hosts |awk '{print $1}')
DIRECTOR_UUID=$(cat director-state/bosh-template-state.json |grep director_id| cut -d"\"" -f4)
DIRECTOR_PASSWORD=$($BOSH_CLI int director-state/credentials.yml --path /DI_ADMIN_PASSWORD)
STEMCELL_NAME=$($BOSH_CLI -e bosh-env stemcells|grep ubuntu-trusty|awk '{print $1}')
STEMCELL_VERSION=$(cat stemcell/version)
SL_VM_DOMAIN=${SL_VM_PREFIX}.softlayer.com
deployment_name=compiled-release

echo "Trying to set target to director: `cat director-state/director-hosts`"

$BOSH_CLI  -e $(cat director-state/director-hosts |awk '{print $2}') --ca-cert <($BOSH_CLI int director-state/credentials.yml --path /DIRECTOR_SSL/ca ) alias-env bosh-env

echo "Trying to login to director..."

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(${BOSH_CLI} int director-state/credentials.yml --path /DI_ADMIN_PASSWORD)

$BOSH_CLI -e bosh-env login

for release_file in compiled-release/*.tgz; do
  echo "Upload release $release_file"
  $BOSH_CLI -e bosh-env upload-release $release_file
done

echo "Generate cf yml file, this must use full release and without cf-service ONLY, or it may fail"
$BOSH_CLI int pipeline-src/ci/tasks/templates/cf-template.yml \
                                                        -v director_password=${DIRECTOR_PASSWORD} \
                                                        -v director_ip=${DIRECTOR} \
                                                        -v director_pub_ip=${DIRECTOR} \
                                                        -v director_uuid=${DIRECTOR_UUID} \
                                                        -v deploy_name=${deployment_name} \
                                                        -v data_center_name=${SL_DATACENTER} \
                                                        -v private_vlan_id=${SL_VLAN_PRIVATE} \
                                                        -v public_vlan_id=${SL_VLAN_PUBLIC} \
                                                        -v stemcell_name=${STEMCELL_NAME}
                                                        -v stemcell_version=${STEMCELL_VERSION} \
                                                        -v cf-release=${cf_release} \
                                                        -v cf-release-version=${cf_release_version} \
                                                        -v mod_vms_release=${mod_vms_release} \
                                                        -v mod_vms_release_version=${mod_vms_release_version} \
                                                        -v security_release=${security_release} \
                                                        -v security_release_version=${security_release_version} \
                                                        -v admin_ui_release=${admin_ui_release} \
                                                        -v admin_ui_release_version=${admin_ui_release_version} \
                                                        -v habr_release=${habr_release} \
                                                        -v habr_release_version=${habr_release_version} \
                                                        -v loginserver_release=${loginserver_release} \
                                                        -v loginserver_release_version=${loginserver_release_version} \
                                                        -v marmot_logstash_forwarder_release=${marmot_logstash_forwarder_release} \
                                                        -v marmot_logstash_forwarder_release_version=${marmot_logstash_forwarder_release_version} \
                                                        -v unbound_release=${unbound_release} \
                                                        -v unbound_release_version=${unbound_release_version} \
                                                        > compiled-deploy/cf-compiled-deploy-${BUILD_VERSION}.yml


echo "Deploy release by using compiled-deploy/cf-compiled-deploy-${BUILD_VERSION}.yml"
$BOSH_CLI -e bosh-env -d ${deployment_name} deploy compiled-deploy/compiled-deploy-${BUILD_VERSION}.yml -n