The pipeline yml file is ci/pipline-compiled-realse.yml

You can create a new Concourse pipeline like this:
fly -t bosh-test set-pipeline -p compile-release-jordan --config ci/pipeline-compiled-release.yml --load-vars-from ~/Work/workspace/credential.yml

There are 6 functions now:
1, prepare-director
2, export-compiled-release
3, upload-compiled-release
4, verify-compiled-deploy
5, delete-compiled-deploy
6, delete-bosh-env

You should prepare a credential.yml by yourself, it like this:
### credential.yml start ###

build_version: 4
bosh_src_url: https://github.com/bluebosh/bosh
stemcell_initial_version: 3363.20.2
bluemix_stemcell_initial_version: 3363.20.2
stemcell_test_director_username: xxx
stemcell_test_director_password: xxx
softlayer_username: xxx
softlayer_api_key: xxx
softlayer_datacenter: lon02
softlayer_vlan_public: "1292653"
softlayer_vlan_private: "1292651"
softlayer_vm_domain: softlayer.com
oftlayer_director_name_prefix: bosh-director-compiled
softlayer_vm_name_prefix: sl-stemcell-compiled-
bat_vcap_password: xxx
stemcell_aws_access_key: xxx
stemcell_aws_secret_key: xxx
s3_pipeline_bucket: bosh-softlayer-cpi-pipeline
candidate_stemcell_bucket: bosh-softlayer-stemcells-candidate-container
candidate_bluemix_stemcell_bucket: bosh-softlayer-stemcells-bluemix-candidate-container
published_stemcell_bucket: bosh-softlayer-cpi-stemcells
published_bluemix_stemcell_bucket: bosh-softlayer-stemcells-bluemix
stemcell_branch: 3363.x
bluemix_stemcell_branch: bluemix
stemcell_version_key: bosh-stemcell/version-3363.x
bluemix_stemcell_version_key: bluemix-stemcell/version-3363.x
stemcell-sl-os-access-key: xxx
stemcell-sl-os-secret-key: xxx
stemcell-sl-os-endpoint: s3-api.us-geo.objectstorage.softlayer.net
candidate-custom-bluemix-stemcell-bucket: bosh-softlayer-compiled-cf-release

cf_release: cf-235029
cf_release_version: ibm-v235.29
cf_release_location:
cf_release_update-name: cf-235029
cf_release_update_version: ibm-v235.29
cf_release_update_location:
cf_services_release: cf-services-235029
cf_services_release_version: ibm-v235.29
cf_services_release_location:
cf_services_contrib_release: cf-services-contrib-235029
cf_services_contrib_release_version: ibm-v235.29
cf_services_contrib_release_location:
mod_vms_release: mod-vms
mod_vms_release_version: v0.0-65
mod_vms_release_location:
security_release: security-release
security_release_version: v0.1-45.3
security_release_location:
admin_ui_release: admin-ui
admin_ui_release_version: 1.5.0.149
admin_ui_release_location:
habr_release: habr
habr_release_version: v1.19-79
habr_release_location:
loginserver_release: loginserver
loginserver_release_version: 2.15-221
loginserver_release_location:
marmot_logstash_forwarder_release: marmot-logstash-forwarder-bosh-release
marmot_logstash_forwarder_release_version: 0+dev.51
marmot_logstash_forwarder_release_location:
unbound_release: unbound
unbound_release_version: v0.2-3
unbound_release_location:

bosh_src_key: |
    xxx
github_private_key: |
    xxx
file_w3_bosh_pem: |
    xxx

### credential.yml end ###



NOTICE:
If you don't want to install the full release, you can just install some special release and just leave other release info as empty like this:
cf_release:
cf_release_version:
cf_release_location:

The default release download address is:
http://10.106.192.96/releases/
You can also replace by using other location like this:
cf_release_location: http://xxx/release/xxx/xxx-version.tgz







Hi Steve and Richard,

In order to speed up release deploy verification, we created a new pre-compiled pipeline to compile special release and upload to s3.
If you want to verify you release, you can download the compiled release tgz file and deploy by using this compiled file.
Then we can skip the compile process during deployment and reduce deployment time.

Hope this new pipeline is helpful and please let me know if you have any suggestion or requirement.

Here is the information if you want to have a try:

1, The example cf compiled deploy pipeline is at:
https://bosh-sl-ci.bluemix.net/teams/ibm-bmx/pipelines/compile-release-jordan
You can login by using your github.com account (Please contact Matt, he can help add your permission)


2, The pipeline process:
  Step 1, Create a new BOSH Director
  Step 2, Export release which you need to tgz file then upload to Softlayer Object Store
  Step 3, Clean the releases info on the new BOSH Director
  Step 4, Deploy your release and verify
  Step 5, Delete BOSH deployments and releases by using the new BOSH Director
  Step 6, Delete the new BOSH Director

After this pipeline is finished, you can download the compiled release tgz file from Softlayer Object Store, like this:
https://s3-api.us-geo.objectstorage.softlayer.net/bosh-softlayer-compiled-release-release/compiled-release/compiled-release-allinone-20170524.tgz

Then you can use this compiled release anywhere or deploy it to other environment.
You can also use this pipeline to upload the release tgz file to file w3, then share to other people.


3, How to use it:
  Step 1, you need a credential.yml to input some credential info and which release and version you would like to compile
  Step 2, Then you need to login and create a special pipeline for your component by using:
    fly -t sl login -c 'https://bosh-sl-ci.bluemix.net' -n ibm-bmx
    fly -t bosh-test set-pipeline -p compile-release-jordan --config ci/pipeline-compiled-release.yml --load-vars-from ~/Work/workspace/credential.yml
    (Please see the attachment file)
  Step 3, Login pipeline portal and kick off your pipeline
