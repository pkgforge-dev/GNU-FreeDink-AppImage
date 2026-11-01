#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook:sdl-soundfonts.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=/usr/share/icons/hicolor/scalable/apps/freedink.svg
export DESKTOP=/usr/share/applications/freedink.desktop
export STARTUPWMCLASS=freedink
export DEPLOY_OPENGL=1

# Deploy dependencies
set -- /usr/bin/freedink /usr/bin/freedinkedit /usr/lib/libfluidsynth.so*
if [ -x /usr/bin/freedink-dfarc ]; then
    set -- "$@" /usr/bin/freedink-dfarc
fi
quick-sharun "$@"

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the app normally quits before that time
# then skip this or check if some flag can be passed that makes it stay open
quick-sharun --simple-test ./dist/*.AppImage
