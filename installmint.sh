#!/usr/bin/env bash
set -euo pipefail

# Ensure script is run as root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must be run as root. Try using sudo."
    exit 1
fi

# -----------------------------
# Configurable directories
# -----------------------------
PLYMOUTH_THEME_BASEDIR=${PLYMOUTH_THEME_BASEDIR:-/usr/share/plymouth/themes/mc}
FONTS_BASEDIR=${FONTS_BASEDIR:-/usr/share/fonts}
FONT_PATH=${FONT_PATH:-/etc/fonts}
FONTCONFIG_PATH=${FONTCONFIG_PATH:-${FONT_PATH}/conf.d}

# -----------------------------
# Check dependencies
# -----------------------------
if command -v magick >/dev/null 2>&1; then
    IMAGEMAGICK_CMD="magick"
elif command -v convert >/dev/null 2>&1; then
    IMAGEMAGICK_CMD="convert"
else
    echo "Error: ImageMagick ('magick' or 'convert' command) is required."
    exit 1
fi

# -----------------------------
# Install font
# -----------------------------
echo "Installing Minecraft font..."
sudo mkdir -p "${FONTS_BASEDIR}/OTF"
sudo cp -v ./font/Minecraft.otf "${FONTS_BASEDIR}/OTF/"
sudo cp -v ./font/config/* "${FONTCONFIG_PATH}/"

# -----------------------------
# Install Plymouth theme
# -----------------------------
echo "Installing Minecraft Plymouth theme..."
sudo mkdir -p "${PLYMOUTH_THEME_BASEDIR}"
sudo cp -v ./plymouth/mc.script "${PLYMOUTH_THEME_BASEDIR}/"
sudo cp -v ./plymouth/mc.plymouth "${PLYMOUTH_THEME_BASEDIR}/"
sudo cp -v ./plymouth/progress_bar.png "${PLYMOUTH_THEME_BASEDIR}/"
sudo cp -v ./plymouth/progress_box.png "${PLYMOUTH_THEME_BASEDIR}/"

# -----------------------------
# Generate resized images
# -----------------------------
echo "Generating scaled images..."
for j in "padlock" "bar"; do
    for i in $(seq 1 6); do
        $IMAGEMAGICK_CMD ./plymouth/${j}.png -interpolate Nearest -filter point -resize "$i"00% \
            "${PLYMOUTH_THEME_BASEDIR}/${j}-${i}.png"
    done
done

for i in $(seq 1 12); do
    $IMAGEMAGICK_CMD ./plymouth/dirt.png \
        -channel R -evaluate multiply 0.25 \
        -channel G -evaluate multiply 0.25 \
        -channel B -evaluate multiply 0.25 \
        -interpolate Nearest -filter point -resize "$i"00% \
        "${PLYMOUTH_THEME_BASEDIR}/dirt-${i}.png"
done

# -----------------------------
# Set theme as default
# -----------------------------
echo "Setting Minecraft Plymouth theme as default..."
sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "${PLYMOUTH_THEME_BASEDIR}/mc.plymouth" 100
sudo update-alternatives --config default.plymouth
sudo update-initramfs -u

echo "Done! Reboot to see your Minecraft boot theme."
