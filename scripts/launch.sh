#!/usr/bin/env bash
set -euo pipefail

# find the first file in ./mkosi.output named DayoServer_*x86-64.raw
image_file=$(find ./mkosi.output -name "DayoServer_*x86-64.raw" | head -n 1)

if [ -z "$image_file" ]; then
    echo "No image file found"
    exit 1
fi
abs_image_file=$(realpath "$image_file")

incus init dayo --empty --vm
incus config device override dayo root size=50GiB
incus config set dayo limits.cpu=4 limits.memory=8GiB
incus config set dayo security.secureboot=false

incus config device add dayo install disk source="$abs_image_file" boot.priority=90
incus start dayo


echo "Dayo is Starting..."
echo "Boot into the Live System (Installer) boot profile."
echo "at the root prompt, enter:"
echo " "
echo "> lsblk"
echo " "
echo "Identify the disk with no partitions, either sda or sdb, then use that below"
echo "> systemd-repart --dry-run=no --empty=force /dev/sdX"

echo " "
echo "When the repart is complete, enter 'systemctl poweroff'"

# this blocks until poweroff
incus console --type=vga dayo

echo "reconfiguring instance..."
sleep 3

incus config device remove dayo install || true
incus start dayo
incus console --type=vga dayo