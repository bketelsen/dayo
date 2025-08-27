#!/usr/bin/env bash
set -euo pipefail

# This script converts a raw disk image (typically produced by mkosi) into an
# ISO-like image that uses 2048-byte logical sectors so it can be treated as a
# CDROM image. It recreates the partition table on the destination image with
# 2048-byte sectors and copies the partition contents.

usage() {
    echo "Usage: $0 <input.img>"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

SRC="$1"
DST="${SRC%.raw}.iso"
if [ "$DST" == "$SRC" ]; then
    DST="${SRC}.iso"
fi

# Copy source to destination (try reflink first for speed if supported)
cp --reflink=auto "$SRC" "$DST" || cp "$SRC" "$DST"

# Make sure there is a little extra room to safely rewrite the partition table
truncate --size +1MiB "$DST"

# Cleanup function to detach loop devices on exit
cleanup() {
    if [ -n "${SRCLOOPDEV:-}" ]; then
        losetup -d "$SRCLOOPDEV" 2>/dev/null || true
    fi
    if [ -n "${DSTLOOPDEV:-}" ]; then
        losetup -d "$DSTLOOPDEV" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Attach source and destination as loop devices. For the source we ask the
# kernel to create partition devices immediately. For the destination we set a
# 2048-byte logical sector size so partitions will be laid out with 2048B
# sectors.
SRCLOOPDEV=$(losetup --find --show --partscan "$SRC")
DSTLOOPDEV=$(losetup --find --show --sector-size 2048 "$DST")

# Read partition metadata from the source loop device (use the loop device,
# not the filename). We grab GUIDs, names and start/end sectors so we can
# recreate the partitions exactly on the destination.
PART1_GUID=$(sgdisk -i 1 "$SRCLOOPDEV" | awk -F': ' '/Partition unique GUID/ {print $2}')
PART2_GUID=$(sgdisk -i 2 "$SRCLOOPDEV" | awk -F': ' '/Partition unique GUID/ {print $2}')
PART2_NAME=$(sgdisk -i 2 "$SRCLOOPDEV" | sed -n "s/Partition name: '\\(.*\\)'/\1/p")

# Extract only the numeric LBA values (sgdisk prints extra "(at ..." text)
PART1_START=$(sgdisk -i 1 "$SRCLOOPDEV" | sed -n "s/First sector:[[:space:]]*\\([0-9]*\\).*/\\1/p")
PART1_END=$(sgdisk -i 1 "$SRCLOOPDEV" | sed -n "s/Last sector:[[:space:]]*\\([0-9]*\\).*/\\1/p")
PART2_START=$(sgdisk -i 2 "$SRCLOOPDEV" | sed -n "s/First sector:[[:space:]]*\\([0-9]*\\).*/\\1/p")
PART2_END=$(sgdisk -i 2 "$SRCLOOPDEV" | sed -n "s/Last sector:[[:space:]]*\\([0-9]*\\).*/\\1/p")

# Determine logical sector sizes on source and destination loop devices and
# convert the LBA values from source sectors to destination sectors. This is
# necessary because the source image uses 512-byte sectors and the destination
# uses 2048-byte sectors.
SRC_SECTOR_SIZE=$(blockdev --getss "$SRCLOOPDEV")
DST_SECTOR_SIZE=$(blockdev --getss "$DSTLOOPDEV")

convert_lba() {
    local lba=$1
    # calculate byte offset then divide by destination sector size
    printf "%d" $(( (lba * SRC_SECTOR_SIZE) / DST_SECTOR_SIZE ))
}

PART1_START_DST=$(convert_lba "$PART1_START")
PART1_END_DST=$(convert_lba "$PART1_END")
PART2_START_DST=$(convert_lba "$PART2_START")
PART2_END_DST=$(convert_lba "$PART2_END")

# Wipe any existing partition data on the destination loop device then create
# partitions using the converted start/end sectors and GUIDs from the source. Use
# standard type codes: EF00 for EFI System, 8300 for Linux filesystem.
sgdisk -Z "$DSTLOOPDEV"
sgdisk -n 1:${PART1_START_DST}:${PART1_END_DST} -u 1:${PART1_GUID} -t 1:EF00 -c 1:esp "$DSTLOOPDEV"
sgdisk -n 2:${PART2_START_DST}:${PART2_END_DST} -u 2:${PART2_GUID} -t 2:8300 -c 2:"${PART2_NAME:-root}" "$DSTLOOPDEV"

# Inform kernel about the new partitions on the destination device. Try partx
# first, fall back to partprobe if needed.
partx -a "$DSTLOOPDEV" || partprobe "$DSTLOOPDEV" || true

SRC_P1="${SRCLOOPDEV}p1"
SRC_P2="${SRCLOOPDEV}p2"
DST_P1="${DSTLOOPDEV}p1"
DST_P2="${DSTLOOPDEV}p2"

# Wait for destination partition device nodes to appear
for i in {1..20}; do
    if [ -b "$DST_P1" ] && [ -b "$DST_P2" ]; then
        break
    fi
    sleep 0.1
done

if [ ! -b "$DST_P1" ] || [ ! -b "$DST_P2" ]; then
    echo "Partition devices for destination not found: $DST_P1 $DST_P2"
    exit 1
fi

# Copy partition contents. Use a reasonable blocksize and ensure data is
# flushed.
dd if="$SRC_P1" of="$DST_P1" bs=4M status=progress conv=fsync
dd if="$SRC_P2" of="$DST_P2" bs=4M status=progress conv=fsync

sync

echo "Converted $SRC -> $DST"
exit 0
