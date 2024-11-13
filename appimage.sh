#!/bin/bash

# Simple recipe to generate an AppImage for this app
# Options:
#   * -u will upload your AppImage file after success to GitHub under "continuous builds"
#
# Requirements:
#   * VERSION as an ENV var, if not detected will use actual GitHub version + commit info
#   * This must be run after a successful build and installation into a prefix passed as the PREFIX variable
#   * Must be run on a Linux version as old as the far distro you need to support, tested on Ubuntu 14.04 Trusty Tar
#   * If you plan to use the "-u" option, configure settings according to https://github.com/probonopd/uploadtool#usage
#
# PREFIX variable must be set before calling this script. It points to the prefix in which gqrx is installed
# PREFIX="micromamba/envs/gqrx"
APP="$PREFIX/bin/gqrx"
DESKTOP="dk.gqrx.gqrx.desktop"
ICON="resources/icons/gqrx.svg"

# clean log space
echo "==================================================================="
echo "                Starting to build the AppImage..."
echo "==================================================================="
echo ""

export VERSION=$(<build/version.txt)

# version notice
echo "You are building Gqrx version: $VERSION"
echo ""

# basic tests
if [ ! -f "$APP" ] ; then
    echo "Error: the app file is not in the path we need it, set the PREFIX var before running this script"
    exit 1
fi

if [ ! -f "$DESKTOP" ] ; then
    echo "Error: can't find the desktop file, please update the DESKTOP var in the script"
    exit 1
fi

if [ ! -f "$ICON" ] ; then
    echo "Error: can't find the default icon, please update the ICON var in the script"
    exit 1
fi

# prepare the ground
rm -rdf AppDir 2>/dev/null
rm -rdf Gqrx-*.AppImage 2>/dev/null

# download & set all needed tools
wget -c -nv "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
wget -c -nv "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage"
wget -c -nv "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod a+x *.AppImage

# build library arguments so Soapy module dependencies are included
soapy_module_libs=("$PREFIX"/lib/SoapySDR/modules*/*)
linuxdeploy_lib_args=()
for lib in ${soapy_module_libs[@]}; do
    linuxdeploy_lib_args+=( "-l" "$lib" )
done

# force libraries that we need
linuxdeploy_lib_args+=(
    "-l" "$PREFIX"/lib/libasound.so.2
    "-l" "$PREFIX"/lib/libexpat.so.1
    "-l" "$PREFIX"/lib/libfontconfig.so.1
    "-l" "$PREFIX"/lib/libfreetype.so.6
    "-l" "$PREFIX"/lib/libgcc_s.so.1
    "-l" "$PREFIX"/lib/libgmp.so.10
    "-l" "$PREFIX"/lib/libgpg-error.so.0
    "-l" "$PREFIX"/lib/libharfbuzz.so.0
    "-l" "$PREFIX"/lib/libjack.so.0
    "-l" "$PREFIX"/lib/libstdc++.so.6
    "-l" "$PREFIX"/lib/libusb-1.0.so.0
    "-l" "$PREFIX"/lib/libuuid.so.1
    "-l" "$PREFIX"/lib/libxcb.so.1
    "-l" "$PREFIX"/lib/libz.so.1
    "-l" "$PREFIX/lib/libuhd.so"
)

mkdir -p ./AppDir/apprun-hooks
echo 'export CONDA_PREFIX="$APPDIR/usr"' >./AppDir/apprun-hooks/soapy-hook.sh
echo 'export UHD_PKG_PATH="$APPDIR/usr"' >./AppDir/apprun-hooks/uhd-hook.sh
echo 'export FONTCONFIG_FILE="$APPDIR/etc/fonts/fonts.conf"
export FONTCONFIG_PATH="$APPDIR/etc/fonts"' >./AppDir/apprun-hooks/fontconfig-hook.sh

# set UHD_IMAGES_DIR to locate UHD firmware images in the AppImage
echo 'export UHD_IMAGES_DIR="$APPDIR/usr/share/uhd/images"' >> ./AppDir/apprun-hooks/uhd-hook.sh

# set QMAKE variable for linuxdeploy-plugin-qt to use PREFIX's Qt
export QMAKE="$PREFIX/bin/qmake6"

./linuxdeploy-x86_64.AppImage -e "$APP" -d "$DESKTOP" -i "$ICON" "${linuxdeploy_lib_args[@]}" -p qt --appdir=./AppDir
RESULT=$?

# copy Soapy modules into expected path in the AppDir
cp -R "$PREFIX"/lib/SoapySDR ./AppDir/usr/lib/SoapySDR

# copy fontconfig configuration files
mkdir -p ./AppDir/etc/
cp -RL "$PREFIX"/etc/fonts ./AppDir/etc/fonts
# remove any config file lines that refer to the old prefix if it's not /usr
if [ "${PREFIX:0:4}" != "/usr" ] ; then
    sed -i "\|$PREFIX|d" ./AppDir/etc/fonts/fonts.conf
fi

# download UHD images
mkdir -p "$PREFIX/share/uhd/images"
"$PREFIX"/lib/uhd/utils/uhd_images_downloader.py

# copy UHD images into AppImage
mkdir -p ./AppDir/usr/share/uhd/images
cp -R "$PREFIX"/share/uhd/images/* ./AppDir/usr/share/uhd/images/

# finally make the AppImage
./appimagetool-x86_64.AppImage AppDir/

# check build success
if [ $RESULT -ne 0 ] ; then
    echo ""
    echo "ERROR: Aborting as something went wrong, please check the logs"
    exit 1
else
    echo ""
    echo "Success build, check your file:"
    ls -lh Gqrx-*.AppImage
fi

# upload if requested
if [ "$1" == "-u" ] ; then
    wget -c https://github.com/probonopd/uploadtool/raw/master/upload.sh
    bash upload.sh Gqrx-*.AppImage
fi
