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
deployment_dir="compiled-deploy"
manifest_filename="compiled-deploy-${BUILD_VERSION}.yml"
deployment_name=compiled-release
mkdir -p $deployment_dir

release_list=(
cf_release
cf_services_release
cf_services_contrib_release
mod_vms_release
security_release
admin_ui_release
habr_release
loginserver_release
marmot_logstash_forwarder_release
unbound_release
)

release_upload_list=()


template_file="pipeline-src/ci/tasks/templates/bluemix-template.yml"
bosh_init_params=""
for release in ${release_list[@]}
do
  release_name=$(eval echo '$'$release)
  release_version=$(eval echo '$'${release}_version)
  release_location=$(eval echo '$'${release}_location)
  echo -e "\nCheck $release information: name: $release_name; version: $release_version; location: $release_location"
  if [ "$release_name" == "" ] || [ "$release_version" == "" ]; then
    echo "name: $release_name or version: $release_version does not exist, remove this release information from template.yml"
    sed -i "/(($release))/d" $template_file
    sed -i "/((${release}_version))/d" $template_file
  else
    bosh_init_params="${bosh_init_params} -v ${release}=${release_name} -v ${release}_version=${release_version}"
    release_upload_list+=("$release")
    echo "$release_name $release_version exists, keep this release"
    if [ "$release_location" == "" ]; then
       echo "Keep using `cat $template_file | grep "((${release}_version))"`"
    else
       echo "Replace location by using $release_location"
       sed -i "s/^- location:.*((${release}_version)).*$/$release_location/g" $template_file
    fi
  fi
done

echo "This is the release parameter list:"
echo "$bosh_init_params"
echo "This is the list which need to be uploaded:"
echo $release_upload_list

$BOSH_CLI int $template_file \
                                                        -v director_password=${DIRECTOR_PASSWORD} \
                                                        -v director_ip=${DIRECTOR} \
                                                        -v director_pub_ip=${DIRECTOR} \
                                                        -v director_uuid=${DIRECTOR_UUID} \
                                                        -v deploy_name=${deployment_name} \
                                                        -v data_center_name=${SL_DATACENTER} \
                                                        -v private_vlan_id=${SL_VLAN_PRIVATE} \
                                                        -v public_vlan_id=${SL_VLAN_PUBLIC} \
                                                        -v stemcell_version=${STEMCELL_VERSION} \
                                                        $bosh_init_params \
                                                        > ${deployment_dir}/${manifest_filename}
#
# upload releases
#
releases=$($BOSH_CLI int ${deployment_dir}/${manifest_filename} --path /releases | grep -Po '(?<=- location: ).*')
while IFS= read -r line; do
  $BOSH_CLI -e bosh-env upload-release $line
done <<< "$releases"

#
# deploy and export
#
$BOSH_CLI -e bosh-env -d ${deployment_name} releases
$BOSH_CLI -e bosh-env -d ${deployment_name} deploy ${deployment_dir}/${manifest_filename} --no-redact -n

for release_upload in ${release_upload_list[@]}
do
  release_upload_name=$(eval echo '$'$release_upload)
  release_upload_version=$(eval echo '$'${release_upload}_version)
  release_tgz_version=`echo $(eval echo '$'${release_upload}_version) | sed "s/\.//g"`
  stemcell_tgz_version=`echo ${STEMCELL_VERSION} | sed "s/\.//g"`
  $BOSH_CLI -e bosh-env -d ${deployment_name} export-release ${release_upload_name}/${release_upload_version} ubuntu-trusty/${STEMCELL_VERSION}

  echo "cp ${release_upload_name}-${release_tgz_version}-ubuntu-trusty-${stemcell_tgz_version}-${BUILD_VERSION}.tgz to folder compiled-release"
  mv ${release_upload_name}-${release_upload_version}-ubuntu-trusty-${STEMCELL_VERSION}-*.tgz compiled-release/
  sha1sum compiled-release/${release_upload_name}-${release_upload_version}-ubuntu-trusty-${STEMCELL_VERSION}-*.tgz
done

tar -cvf compiled-release-allinone-${BUILD_VERSION}.tgz compiled-release/
rm -rf compiled-release/*
mv compiled-release-allinone-${BUILD_VERSION}.tgz compiled-release/
sha1sum compiled-release/compiled-release-allinone-${BUILD_VERSION}.tgz
echo "You can download the compiled-release-allinone-${BUILD_VERSION}.tgz file from SL S3 by using this url after finish:"
echo "https://s3-api.us-geo.objectstorage.softlayer.net/bosh-softlayer-compiled-release-release/compiled-release/compiled-release-allinone-${BUILD_VERSION}.tgz"