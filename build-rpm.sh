#!/bin/bash
# Simple on-device RPM builder for System Ninja
# Run this from the project root

set -e

NAME=system-ninja
VERSION=1.0.1
RELEASE=1
ARCH=noarch

BUILDROOT=$(pwd)/buildroot
RPMDIR=$(pwd)/rpms
SOURCES=$(pwd)/sources

echo "=== Cleaning ==="
rm -rf "$BUILDROOT" "$RPMDIR" "$SOURCES"
mkdir -p "$BUILDROOT" "$RPMDIR" "$SOURCES"

echo "=== Preparing source tarball ==="
mkdir -p "$SOURCES/$NAME-$VERSION"
cp -r main.qml backend.py launch.sh system-ninja.desktop \
   app-icon.png cover pages rpm \
   "$SOURCES/$NAME-$VERSION/"

cd "$SOURCES"
tar czf "$NAME-$VERSION.tar.gz" "$NAME-$VERSION"
cd -

echo "=== Preparing buildroot ==="
mkdir -p "$BUILDROOT/usr/share/$NAME"
mkdir -p "$BUILDROOT/usr/share/applications"
mkdir -p "$BUILDROOT/usr/share/icons/hicolor/86x86/apps"
mkdir -p "$BUILDROOT/usr/share/icons/hicolor/108x108/apps"
mkdir -p "$BUILDROOT/usr/share/icons/hicolor/128x128/apps"
mkdir -p "$BUILDROOT/usr/share/icons/hicolor/256x256/apps"

cp main.qml backend.py launch.sh app-icon.png "$BUILDROOT/usr/share/$NAME/"
cp -r cover pages "$BUILDROOT/usr/share/$NAME/"
cp system-ninja.desktop "$BUILDROOT/usr/share/applications/"
cp app-icon.png "$BUILDROOT/usr/share/icons/hicolor/86x86/apps/$NAME.png"
cp app-icon.png "$BUILDROOT/usr/share/icons/hicolor/108x108/apps/$NAME.png"
cp app-icon.png "$BUILDROOT/usr/share/icons/hicolor/128x128/apps/$NAME.png"
cp app-icon.png "$BUILDROOT/usr/share/icons/hicolor/256x256/apps/$NAME.png"

echo "=== Building RPM ==="
# Try rpmbuild first, fall back to manual rpm if not available
if which rpmbuild >/dev/null 2>&1; then
    rpmbuild -bb --buildroot "$BUILDROOT" \
        --define "_rpmdir $RPMDIR" \
        --define "_sourcedir $SOURCES" \
        --define "_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" \
        rpm/$NAME.spec
else
    echo "rpmbuild not found. Trying manual rpm build..."
    # This is a simplified approach - may not work on all systems
    # Install rpm-build for proper packaging
    echo "Please install rpm-build:"
    echo "  1. Find the rpm-build RPM for your arch"
    echo "  2. Install: rpm -ivh --nodeps rpm-build-*.rpm"
    exit 1
fi

echo "=== Done ==="
ls -la "$RPMDIR"/*.rpm 2>/dev/null || ls -la "$RPMDIR"/noarch/*.rpm 2>/dev/null
echo ""
echo "Install with: devel-su rpm -ivh --nodeps <rpmfile>"
