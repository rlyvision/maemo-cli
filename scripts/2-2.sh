#!/bin/bash
set -Eeuo pipefail

clear

TMP="/tmp/maemo"
IMAGE="$TMP/maemo-leste-5.0-armhf-n900-20251228.img.xz"
TOOLS="$TMP/tools"
IMAGE_LINK="https://maedevu.maemo.org/images/n900/20251228-daedalus/maemo-leste-5.0-armhf-n900-20251228.img.xz"

read -rp "Are you on the Nokia N900? (yes/no) " on_n900

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

if [[ "$on_n900" == "yes" ]]; then
    apt-get install -y u-boot-flasher
    uname -a

    read -rp "Is your kernel a power kernel? (yes/no) " power_kernel
    if [[ "$power_kernel" != "yes" ]]; then
        apt-get install -y kernel-power-bootimg || true
    fi

    cat > /etc/bootmenu.d/30-maemo-leste.item << __EOF__
ITEM_NAME="Maemo Leste"
ITEM_KERNEL="uImage"
ITEM_DEVICE="\${EXT_CARD}p1"
ITEM_FSTYPE="ext2"
__EOF__

    u-boot-update-bootmenu
fi

read -rp "This will install Maemo Leste and WIPE your phone. Continue? (yes/no) " confirm_install
[[ "$confirm_install" == "yes" ]] || { echo "Aborted."; exit 1; }

for cmd in wget unzip git dd lsblk xz; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing required tool: $cmd"
        exit 1
    }
done

mkdir -p "$TMP" "$TOOLS"

echo "Downloading image..."
if [ ! -f "$IMAGE" ]; then
    wget -O "$IMAGE" "$IMAGE_LINK"
else
    echo "Image already exists."
fi

echo "Downloading tools..."
if [ -z "$(ls -A "$TOOLS" 2>/dev/null)" ]; then
    wget -r -np -nH --cut-dirs=4 -R "index.html*" \
        -P "$TOOLS" https://maedevu.maemo.org/images/n900/tools/
else
    echo "Tools already downloaded."
fi

echo
echo "Available removable block devices:"
lsblk -dpno NAME,SIZE,MODEL,RM | awk '$4 == 1 {print}'
echo

read -rp "Enter FULL device path for SD card (example: /dev/sdb): " DEVICE

[[ -b "$DEVICE" ]] || { echo "Not a valid block device."; exit 1; }
[[ "$(lsblk -no RM "$DEVICE")" == "1" ]] || {
    echo "Refusing to write to non-removable device!"
    exit 1
}

echo
echo "WARNING: ALL DATA on $DEVICE will be destroyed."
read -rp "Type EXACTLY: ERASE-SD to continue: " CONFIRM
[[ "$CONFIRM" == "ERASE-SD" ]] || { echo "Aborted."; exit 1; }

echo "Writing image..."
xz -dc "$IMAGE" | dd of="$DEVICE" bs=4M status=progress conv=fsync
sync

echo "SD card write complete."
read -rp "Remove the SD card and insert into N900. Press Enter to continue."

read -rp "Configure Maemo Leste from Fremantle? (yes/no) " configure_choice

if [[ "$configure_choice" == "no" ]]; then
    read -rp "Keep existing Fremantle installation? (yes/no) " keep_fremantle

    if [[ "$keep_fremantle" == "no" ]]; then
        read -rp "Connect device to USB and press Enter."
        "$TOOLS/0xFFFF" -m "$TOOLS/u-boot-2013.04-2.bin" -f
    fi

    read -rp "Connect device to USB and press Enter."
    "$TOOLS/0xFFFF" -m "$TOOLS/u-boot-2013.04-2.bin" -l

    read -rp "Open keyboard slider and press Enter."
    "$TOOLS/0xFFFF" -b
fi

echo "Run this script again on the N900."
