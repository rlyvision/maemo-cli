mkdir /tmp/maemo
echo "Downloading latest Virtual Box version."
curl --progress-bar https://maedevu.maemo.org/images/virtual-machines/20251228-daedalus/maemo-leste-5.0-amd64-20251228.vdi.xz -o /tmp/maemo/maemo-leste-5.0-amd64-20251228.vdi.xz
echo "Install done, copy from '/tmp/maemo/maemo-leste-5.0-amd64-20251228.vdi.xz' to your target location.