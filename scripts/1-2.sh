#!/usr/bin/env bash
set -Eeuo pipefail

clear

TMP="/tmp/maemo"
STOCK_FW_FILE="$TMP/VRZ_XT894_9.8.2O-72_VZW-18-8_CFC.xml.zip"
STOCK_FW_DIR="$TMP/VRZ_XT894_9.8.2O-72_VZW-18-8_CFC.xml"
IMAGE="$TMP/maemo-leste-5.0-armhf-droid4-20251228.img.xz"
KEXECDIR="$TMP/droid4-kexecboot"
STOCK_FW_LINK="https://maedevu.maemo.org/images/droid4/VRZ_XT894_9.8.2O-72_VZW-18-8_CFC.xml.zip"
FW_FLASH_LINK="https://maedevu.maemo.org/images/droid4/flash-droid-4-fw.sh"
FW_FLASH_FILE="$TMP/VRZ_XT894_9.8.2O-72_VZW-18-8_CFC.xml/flashfw.sh"
IMAGE_LINK="https://maedevu.maemo.org/images/droid4/20251228-daedalus/maemo-leste-5.0-armhf-droid4-20251228.img.xz"

read -rp "This will install Maemo Leste and WIPE your phone. This will be an attended installation. Continue? (yes/no) " yn
[[ "$yn" == "yes" ]] || { echo "Aborted."; exit 1; }

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

for cmd in fastboot adb wget unzip dd lsblk xz; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing required tool: $cmd"
        exit 1
    }
done

mkdir -p "$TMP"

read -rp "Is your Droid 4 atleast kernel 3.0.8? (yes/no) " yn
[[ "$yn" == "no" ]] || {
    if [[ ! -f "$STOCK_FW_FILE" ]]; then
        wget -O "$STOCK_FW_FILE" "$STOCK_FW_LINK"
        mkdir -p "$STOCK_FW_DIR"
        unzip "$STOCK_FW_FILE" -d "$STOCK_FW_DIR"
        wget -O "$FW_FLASH_FILE" -d "$FW_FLASH_LINK"
        read -rp "Reboot to fastboot and press enter..."
        "$FW_FLASH_FILE"
    fi
}

if [[ ! -d "$KEXECDIR" ]]; then
    mkdir "$KEXECDIR"
    wget -O "$KEXECDIR/droid4-kexecboot.img" https://github.com/tmlind/droid4-kexecboot/blob/master/2023-12-26/droid4-kexecboot.img
    wget -O "$KEXECDIR/utags-mmcblk1p13.bin" https://github.com/tmlind/droid4-kexecboot/raw/refs/heads/master/utags-xt894-16-mmcblk1p8-boots-mmcblk1p13-kexecboot.bin
fi

if [[ ! -f "$IMAGE" ]]; then
    wget -O "$IMAGE" "$IMAGE_LINK"
fi

read -rp "Boot phone into fastboot mode and press Enter..."
fastboot flash "$STOCK_FW_DIR/allow-mbmloader-flashing-mbm.bin"
fastboot reboot-bootloader
fastboot flash bpsw "$KEXECDIR/droid4-kexecboot.img"
fastboot flash utags "$KEXECDIR/utags-mmcblk1p13.bin"
fastboot reboot
echo "Device flashing done"
echo
echo "Available removable block devices:"
lsblk -dpno NAME,SIZE,MODEL,RM | grep " 1$" || true
echo

read -rp "Enter FULL device path for SD card (example: /dev/sdb): " DEVICE

if [[ ! -b "$DEVICE" ]]; then
    echo "Not a valid block device."
    exit 1
fi

if [[ "$(lsblk -no RM "$DEVICE")" != "1" ]]; then
    echo "Refusing to write to non-removable device!"
    exit 1
fi

echo
echo "WARNING: ALL DATA on $DEVICE will be destroyed."
read -rp "Type EXACTLY: ERASE-SD to continue: " CONFIRM

[[ "$CONFIRM" == "ERASE-SD" ]] || {
    echo "Aborted."
    exit 1
}

echo
echo "Writing image to SD card..."
xz -dc "$IMAGE" | dd of="$DEVICE" bs=4M status=progress conv=fsync

sync
echo "SD card write complete."
echo "Cleaning up temporary files..."
rm -rf "$TMP"
echo "Done."
