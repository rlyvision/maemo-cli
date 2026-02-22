echo "Downloading latest Virtual Box image..."

mkdir -p /tmp/maemo

cd /tmp/maemo || exit 1

wget https://maedevu.maemo.org/images/virtual-machines/20260219-daedalus/maemo-leste-5.0-amd64-20260219.vdi.xz
unxz maemo-leste-5.0-amd64-20251228.qcow2.xz
echo "Download complete."
echo "File saved to: /tmp/maemo/maemo-leste-5.0-amd64-20251228.qcow2"