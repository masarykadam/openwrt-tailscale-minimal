#!/bin/sh
set -e

cd "$(dirname "$0")/tailscale"

# Checkout specific version (default: latest stable tag)
VERSION="${1:-$(git tag -l 'v[0-9]*' | grep -v pre | sort -V | tail -1)}"
echo "Checking out $VERSION..."
git fetch --tags
git checkout "$VERSION"

TAGS="ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_completion,ts_omit_kube,ts_omit_systray,ts_omit_taildrop,ts_omit_tap,ts_omit_tpm,ts_omit_acme,ts_omit_appconnectors,ts_omit_capture,ts_omit_cloud,ts_omit_colorable,ts_omit_completion_scripts,ts_omit_dbus,ts_omit_debug,ts_omit_debugeventbus,ts_omit_debugportmapper,ts_omit_desktop_sessions,ts_omit_doctor,ts_omit_drive,ts_omit_identityfederation,ts_omit_networkmanager,ts_omit_oauthkey,ts_omit_posture,ts_omit_qrcodes,ts_omit_relayserver,ts_omit_sdnotify,ts_omit_synology,ts_omit_syspolicy,ts_omit_webclient,ts_omit_webbrowser,ts_omit_tailnetlock,ts_omit_ace,ts_omit_conn25,ts_omit_outboundproxy,ts_omit_peerapiclient,ts_omit_peerapiserver,ts_omit_usermetrics,ts_omit_netlog,ts_omit_tundevstats,ts_omit_linkspeed"

VERSION_SHORT="${VERSION#v}"

echo "Building tailscale $VERSION for linux/arm64..."
GOOS=linux GOARCH=arm64 go build -o ../tailscale.combined \
  -tags "$TAGS" \
  -trimpath \
  -ldflags "-s -w -X 'tailscale.com/version.longStamp=${VERSION_SHORT}-openwrt' -X 'tailscale.com/version.shortStamp=${VERSION_SHORT}'" \
  ./cmd/tailscaled

echo "Compressing with UPX..."
upx -d ../tailscale.combined 2>/dev/null || true
upx --lzma --best ../tailscale.combined

echo "Packaging..."
cp ../tailscale.combined ../package/usr/sbin/tailscale.combined
chmod +x ../package/usr/sbin/tailscale.combined
cd ../package
tar -czf ../tailscale-openwrt.tgz usr etc

echo ""
ls -lh ../tailscale-openwrt.tgz
echo "Done! Now run:"
echo "  scp -O ~/Downloads/openwrt_tailscale/tailscale-openwrt.tgz root@192.168.1.1:/tmp/"
