#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_config.bash
source $base_dir/lib/helpers.sh

if [ -z "${base_debootstrap_suite:-}" ]
then
  base_debootstrap_suite=$stemcell_operating_system_version
fi

persist_value base_debootstrap_arch
persist_value base_debootstrap_suite
