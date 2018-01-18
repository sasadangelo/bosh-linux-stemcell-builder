#!/usr/bin/env bash

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

# Set SettingsPath but never use it because file_meta_service is avaliable only when the settings file exists.
cat > $chroot/var/vcap/bosh/agent.json <<JSON
{
  "Platform": {
    "Linux": {
      "CreatePartitionIfNoEphemeralDisk": true,
      "ScrubEphemeralDisk": true,
      "DevicePathResolutionType": "iscsi"
    }
  },
  "Infrastructure": {
    "Settings": {
      "Sources": [
        {
          "Type": "InstanceMetadata",
          "URI": "https://api.service.softlayer.com",
          "SettingsPath": "/rest/v3.1/SoftLayer_Resource_Metadata/getUserMetadata.json",
        }
      ],
      "UseRegistry": false
    }
  }
}
JSON