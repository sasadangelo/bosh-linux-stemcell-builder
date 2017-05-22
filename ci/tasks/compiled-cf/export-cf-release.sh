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

#
# target/authenticate
#

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

ls -al
ls -al stemcell

$BOSH_CLI -e bosh-env upload-stemcell stemcell/light-bosh-stemcell-*.tgz

DIRECTOR=$(cat director-state/director-hosts |awk '{print $1}')
DIRECTOR_UUID=$(cat director-state/bosh-template-state.json |grep director_id| cut -d"\"" -f4)
DIRECTOR_PASSWORD=$($BOSH_CLI int director-state/credentials.yml --path /DI_ADMIN_PASSWORD)
STEMCELL_NAME=$($BOSH_CLI -e bosh-env stemcells|grep ubuntu-trusty|awk '{print $1}')
STEMCELL_VERSION=$(cat stemcell/version)
SL_VM_DOMAIN=${SL_VM_PREFIX}.softlayer.com
deployment_dir="${PWD}/cf-deployment"
manifest_filename="cf-manifest.yml"
deployment_name=compiled-cf
mkdir -p $deployment_dir

$BOSH_CLI int pipeline-src/ci/tasks/templates/bluemix-template.yml \
                                                        -v director_password=${DIRECTOR_PASSWORD} \
                                                        -v director_ip=${DIRECTOR} \
                                                        -v director_pub_ip=${DIRECTOR} \
                                                        -v director_uuid=${DIRECTOR_UUID} \
                                                        -v deploy_name=${deployment_name} \
                                                        -v data_center_name=${SL_DATACENTER} \
                                                        -v private_vlan_id=${SL_VLAN_PRIVATE} \
                                                        -v public_vlan_id=${SL_VLAN_PUBLIC} \
                                                        -v stemcell_version=${STEMCELL_VERSION} \
                                                        -v unbound_release=${unbound_release} \
                                                        -v unbound_release_version=${unbound_release_version} \
                                                        > ${deployment_dir}/${manifest_filename}
#
# upload releases
#
releases=$($BOSH_CLI int ${deployment_dir}/${manifest_filename} --path /releases |grep -Po '(?<=- location: ).*')
while IFS= read -r line; do
  $BOSH_CLI -e bosh-env upload-release $line
done <<< "$releases"

#
# deploy and export
#
$BOSH_CLI -e bosh-env -d ${deployment_name} releases
$BOSH_CLI -e bosh-env -d ${deployment_name} deploy ${deployment_dir}/${manifest_filename} --no-redact -n
$BOSH_CLI -e bosh-env -d ${deployment_name} export-release ${cf_release}/${cf_release_version} ubuntu-trusty/${STEMCELL_VERSION}

echo "cp ${cf_release}-${cf_release_version}-ubuntu-trusty-${STEMCELL_VERSION}-${BUILD_VERSION}.tgz to folder compiled-release"
mv ${cf_release}-${cf_release_version}-ubuntu-trusty-${STEMCELL_VERSION}-*.tgz unbound-compiled-release-${BUILD_VERSION}.tgz
mv unbound-compiled-release-${BUILD_VERSION}.tgz compiled-release/

#
# currently comment out these releases
#
#$BOSH_CLI -e bosh-env -d ${deployment_name} export-release ${cf_services_release}/${cf_services_release_version} ubuntu-trusty/${STEMCELL_VERSION}
#$BOSH_CLI -e bosh-env -d ${deployment_name} export-release ${cf_services_contrib_release}/${cf_services_contrib_release_version} ubuntu-trusty/${STEMCELL_VERSION}
#$BOSH_CLI -e bosh-env -d ${deployment_name} export-release ${mod_vms_release}/${mod_vms_release_version} ubuntu-trusty/${STEMCELL_VERSION}
#$BOSH_CLI -e bosh-env -d ${deployment_name} export-release ${security_release}/${security_release_version} ubuntu-trusty/${STEMCELL_VERSION}
#$BOSH_CLI -e bosh-env -d ${deployment_name} export-release ${admin_ui_release}/${admin_ui_release_version} ubuntu-trusty/${STEMCELL_VERSION}
#$BOSH_CLI -e bosh-env -d ${deployment_name} export-release ${habr_release}/${habr_release_version} ubuntu-trusty/${STEMCELL_VERSION}
#$BOSH_CLI -e bosh-env -d ${deployment_name} export-release ${loginserver_release}/${loginserver_release_version} ubuntu-trusty/${STEMCELL_VERSION}
#$BOSH_CLI -e bosh-env -d ${deployment_name} export-release ${marmot_logstash_forwarder_release}/${marmot_logstash_forwarder_release_version} ubuntu-trusty/${STEMCELL_VERSION}
#$BOSH_CLI -e bosh-env -d ${deployment_name} export-release ${unbound_release}/${unbound_release_version} ubuntu-trusty/${STEMCELL_VERSION}

sha1sum compiled-release/cf-compiled-release-${BUILD_VERSION}.tgz

echo "You can download the cf-compiled-release-${BUILD_VERSION}.tgz file from SL S3 by using this url after finish:"
echo "https://s3-api.us-geo.objectstorage.softlayer.net/bosh-softlayer-compiled-cf-release/compiled-release/cf-compiled-release-${BUILD_VERSION}.tgz"
