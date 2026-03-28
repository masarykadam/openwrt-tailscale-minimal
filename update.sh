#!/bin/sh
# Tailscale updater for OpenWrt
# Usage: /usr/sbin/tailscale-update [version]
# Without arguments, installs the latest release.
set -e

REPO="masarykadam/openwrt-tailscale-minimal"
CURRENT=$(tailscale version 2>/dev/null | head -1 | sed 's/-openwrt//' || echo "none")

if [ -n "$1" ]; then
    VERSION="$1"
    VERSION_SHORT="${VERSION#v}"
else
    echo "Checking for latest version..."
    VERSION=$(wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" | \
        grep '"tag_name"' | sed 's/.*"tag_name": *"//;s/".*//')
    VERSION_SHORT="${VERSION#v}"
fi

if [ -z "$VERSION" ]; then
    echo "Error: could not determine latest version"
    exit 1
fi

echo "Current: $CURRENT"
echo "Latest:  $VERSION_SHORT"

if [ "$CURRENT" = "$VERSION_SHORT" ]; then
    echo "Already up to date."
    exit 0
fi

URL="https://github.com/${REPO}/releases/download/${VERSION}/tailscale-openwrt-${VERSION_SHORT}.tgz"

echo "Downloading tailscale ${VERSION_SHORT}..."
wget -O /tmp/tailscale-openwrt.tgz "$URL"

echo "Installing..."
/etc/init.d/tailscale stop
tar x -zvC / -f /tmp/tailscale-openwrt.tgz
rm /tmp/tailscale-openwrt.tgz
/etc/init.d/tailscale start

echo ""
echo "Updated to $(tailscale version | head -1)"
