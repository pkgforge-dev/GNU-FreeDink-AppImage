#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm    \
    fluidsynth             \
    glm                    \
    help2man               \
    intltool               \
    python-distutils-extra \
    python-setuptools      \
    rsync                  \
    sdl2_gfx               \
    sdl2_mixer             \
    sdl2_ttf               \
    wxwidgets-gtk3

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano libdecor-mini sdl2_image-mini

# Comment this out if you need an AUR package
#make-aur-package cxxtest
#make-aur-package this was being used to compile the PKGBUILD

echo "Building cxxtest..."
echo "---------------------------------------------------------------"
REPO="https://github.com/CxxTest/cxxtest"
git clone --depth 1 "$REPO" ./cxxtest

cd ./cxxtest/python
python setup.py install --root="/usr" --optimize=1
cd ../..

echo "Building GNU FreeDink..."
echo "---------------------------------------------------------------"
VERSION=109.6
echo "$VERSION" > ~/version
REPO="https://ftp.gnu.org/gnu/freedink/freedink-${VERSION}.tar.gz"

DATA_VERSION=1.08.20190120
DFARC_VERSION=3.14
PATCHES="$PWD/patches"

curl -fL "$REPO" | tar xz
curl -fL "https://ftp.gnu.org/gnu/freedink/freedink-data-${DATA_VERSION}.tar.gz" | tar xz
curl -fL "https://ftp.gnu.org/gnu/freedink/dfarc-${DFARC_VERSION}.tar.gz" | tar xz

cd "freedink-${VERSION}"
patch -p1 < "$PATCHES/sdl2-2.0.10.patch"
patch -p1 < "$PATCHES/backport.patch"
patch -p1 < "$PATCHES/gfxfonts-fix.patch"
patch -p1 < "$PATCHES/config.h.patch"
sed '/dversion_string = "v1.08 FreeDink";/ s/v1.08/v1.09/' -i src/game_engine.cpp
./configure --prefix=/usr --disable-tests
make -j1
make install
cd ..

cd "freedink-data-${DATA_VERSION}"
patch -p1 < "$PATCHES/backport-translations.patch"
make install PREFIX=/usr
cd ..

cd "dfarc-${DFARC_VERSION}"
sed '/^  mDinkExe/   s/"dink"/"freedink"/'         -i src/Config.cpp
sed '/^  mEditorExe/ s/"dinkedit"/"freedinkedit"/' -i src/Config.cpp
if ./configure --prefix=/usr --disable-desktopfiles --with-wx-config=/usr/bin/wx-config \
    && make \
    && make install; then
    sed 's/Exec=dfarc/Exec=freedink-dfarc/' -i /usr/share/applications/freedink-dfarc.desktop
    echo "NoDisplay=true" >> /usr/share/applications/freedink-dfarc.desktop
    rm -f /usr/bin/freedink-dfarc
    mv /usr/bin/dfarc /usr/bin/freedink-dfarc
fi
cd ..
rm -f /usr/bin/dink /usr/bin/dinkedit
