#!/bin/bash
set -e

clear
read -p "This will install Maemo Leste on your Droid 3. This will wipe your data. This is an attended installation. Continue? (yes/no) " yn
case "$yn" in
    yes ) echo "Proceeding...";;
    no ) echo "Aborting."; exit 0;;
    * ) echo "Invalid response, please enter yes or no."; exit 1;;
esac
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi
if ! command -v fastboot >/dev/null 2>&1; then
    echo "Fastboot does not exist. Please install it using your package manager before proceeding."
    exit 1
fi

if ! command -v adb >/dev/null 2>&1; then
    echo "ADB tools do not exist. Please install them using your package manager before proceeding."
    exit 1
fi
stockfwfile="/tmp/maemo/VRZ_XT862_5.5.1_84_D3G-66_M2-10_1FF_01a.xml.zip"
read -p "Is your Droid 3 on Android version 2.3.4 or older? (yes/no) " yn
case "$yn" in
    yes ) echo "Proceeding...";;
    no ) echo "Please follow the guide at https://maedevu.maemo.org/images/solana/README.txt instead"; exit 1;;
    * ) echo "Invalid response, please enter yes or no."; exit 1;;
esac

mkdir -p /tmp/maemo
if [[ ! -f $stockfwfile ]]; then
    wget -O $stockfwfile https://firmware.center/firmware/Motorola/Android/XT862%20Droid%203%20%28Solana%29/Flash%20Files/Stock/VRZ_XT862_5.5.1_84_D3G-66_M2-10_1FF_01a.xml.zip
    mkdir -p /tmp/maemo/VRZ_XT862_5.5.1_84_D3G-66_M2-10_1FF_01a.xml
    unzip $stockfwfile -d /tmp/maemo/VRZ_XT862_5.5.1_84_D3G-66_M2-10_1FF_01a.xml
fi
if [[ ! -d "/tmp/maemo/bionic-clown-boot" ]]; then
    git clone https://github.com/MerlijnWajer/bionic-clown-boot.git /tmp/maemo/bionic-clown-boot
    cp /tmp/maemo/bionic-clown-boot/flash-droid-3-fw.sh /tmp/maemo/VRZ_XT862_5.5.1_84_D3G-66_M2-10_1FF_01a.xml/flashfw.sh
fi
if [[ ! -f "/tmp/maemo/maemo-leste-5.0-armhf-droid3-20251228.img.xz" ]]; then
    wget -O /tmp/maemo/maemo-leste-5.0-armhf-droid3-20251228.img.xz https://maedevu.maemo.org/images/droid3/20251228-daedalus/maemo-leste-5.0-armhf-droid3-20251228.img.xz
fi
cp -f /tmp/maemo/bionic-clown-boot/flash-droid-3-fw.sh \
      /tmp/maemo/VRZ_XT862_5.5.1_84_D3G-66_M2-10_1FF_01a.xml/flashfw.sh
read -p "Please set your phone to fastboot and press enter"
/tmp/maemo/VRZ_XT862_5.5.1_84_D3G-66_M2-10_1FF_01a.xml/flashfw.sh
fastboot reboot recovery
read -p "Please select wipe data / factory reset and press enter"
read -p "Reboot device to android, enable usb debugging, and connect usb then press enter"
/tmp/maemo/bionic-clown-boot/root234.sh
read -p "Wait for device to go to gui again and press enter"
/tmp/maemo/bionic-clown-boot/install.sh
adb reboot fastboot
fastboot flash mbm /tmp/maemo/bionic-clown-boot/flash mbm allow-mbmloader-flashing-mbm.bin
fastboot reboot bootloader
wget -O /tmp/maemo/droid4-kexecboot.img https://github.com/tmlind/droid4-kexecboot/raw/refs/heads/master/2023-12-26/droid4-kexecboot.img
fastboot flash bpsw /tmp/maemo/droid4-kexecboot.img
fastboot flash boot /tmp/maemo/bionic-clown-boot/boot.img
fastboot reboot
echo "Device is done flashing" 
echo "Available block devices:"
lsblk -dpno NAME,SIZE,MODEL | grep -v loop

echo
read -p "Enter the full device path for the SD card (e.g. /dev/sdb): " DEVICE
IMAGE=/tmp/maemo/maemo-leste-5.0-armhf-droid3-20251228.img.xz
if [ ! -b "$DEVICE" ]; then
    echo "Error: $DEVICE is not a valid block device."
    exit 1
fi

echo
echo "WARNING: This will ERASE all data on $DEVICE"
read -p "Type YES to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Aborted."
    exit 1
fi

read -p "Enter path to image file (.img): " IMAGE

if [ ! -f "$IMAGE" ]; then
    echo "Error: Image file not found."
    exit 1
fi

echo
echo "Writing $IMAGE to $DEVICE ..."
sudo dd if="$IMAGE" of="$DEVICE" bs=4M status=progress conv=fsync

echo
echo "Done."

