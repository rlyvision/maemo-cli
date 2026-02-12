mkdir /tmp/maemo
echo "Downloading latest ARM64 Generic version."
curl --progress-bar https://maedevu.maemo.org/images/arm64-generic/20251228-daedalus/maemo-leste-5.0-arm64-arm64-generic-20251228.img.xz -o /tmp/maemo/maemo-leste-5.0-arm64-arm64-generic-20251228.img.xz
echo "Install done, copy from '/tmp/maemo/maemo-leste-5.0-arm64-arm64-generic-20251228.img.xz' to your target location.