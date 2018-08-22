#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

# Copy over some other system assets
# Networking...
cp $assets_dir/etc/hosts $chroot/etc/hosts

# Timezone
cp $assets_dir/etc/timezone $chroot/etc/timezone

run_in_chroot $chroot "dpkg-reconfigure -fnoninteractive -pcritical tzdata"

# Locale
cp $assets_dir/etc/default/locale $chroot/etc/default/locale
run_in_chroot $chroot "locale-gen en_US.UTF-8"
run_in_chroot $chroot "dpkg-reconfigure locales"
