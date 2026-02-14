#!/usr/bin/env bash
set -Eeuo pipefail

clear

TMP="/tmp/maemo"
STOCK_FW_FILE="$TMP/VRZ_XT862_5.5.1_84_D3G-66_M2-10_1FF_01a.xml.zip"
STOCK_FW_DIR="$TMP/VRZ_XT862_5.5.1_84_D3G-66_M2-10_1FF_01a.xml"
IMAGE="$TMP/maemo-leste-5.0-armhf-droid3-20251228.img.xz"
KEXECDIR="$TMP/bionic-clown-boot"

STOCK_FW_LINK="https://firmware.center/firmware/Motorola/Android/XT862%20Droid%203%20%28Solana%29/Flash%20Files/Stock/VRZ_XT862_5.5.1_84_D3G-66_M2-10_1FF_01a.xml.zip"
IMAGE_LINK="https://maedevu.maemo.org/images/droid3/20251228-daedalus/maemo-leste-5.0-armhf-droid3-20251228.img.xz"

read -rp "This will install Maemo Leste and WIPE your phone. This will be an attended installation. Continue? (yes/no) " yn
[[ "$yn" == "yes" ]] || { echo "Aborted."; exit 1; }

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

for cmd in fastboot adb wget unzip git dd lsblk xz; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing required tool: $cmd"
        exit 1
    }
done

read -rp "Is your Droid 3 on Android 2.3.4 or older? (yes/no) " yn
[[ "$yn" == "yes" ]] || {
    echo "Follow the manual guide instead."
    exit 1
}

mkdir -p "$TMP"

if [[ ! -f "$STOCK_FW_FILE" ]]; then
    wget -O "$STOCK_FW_FILE" "$STOCK_FW_LINK"
    mkdir -p "$STOCK_FW_DIR"
    unzip "$STOCK_FW_FILE" -d "$STOCK_FW_DIR"
fi

if [[ ! -d "$KEXECDIR" ]]; then
    git clone https://github.com/MerlijnWajer/bionic-clown-boot.git "$KEXECDIR"
fi

cp -f "$KEXECDIR/flash-droid-3-fw.sh" "$STOCK_FW_DIR/flashfw.sh"

if [[ ! -f "$IMAGE" ]]; then
    wget -O "$IMAGE" "$IMAGE_LINK"
fi

read -rp "Boot phone into fastboot mode and press Enter..."

"$STOCK_FW_DIR/flashfw.sh"

fastboot reboot recovery
read -rp "Wipe data/factory reset in recovery, then press Enter..."

read -rp "Boot into Android, enable USB debugging, connect USB, press Enter..."
"$KEXECDIR/root234.sh"

read -rp "Wait until device boots fully, then press Enter..."
"$KEXECDIR/install.sh"

adb reboot fastboot

fastboot flash mbm "$KEXECDIR/flash/allow-mbmloader-flashing-mbm.bin"
fastboot reboot bootloader

wget -O "$TMP/droid4-kexecboot.img" \
https://github.com/tmlind/droid4-kexecboot/raw/refs/heads/master/2023-12-26/droid4-kexecboot.img

fastboot flash bpsw "$TMP/droid4-kexecboot.img"
fastboot flash boot "$KEXECDIR/boot.img"
fastboot reboot

echo "Phone flashing complete."

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