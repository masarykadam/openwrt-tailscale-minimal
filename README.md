# Tailscale for OpenWrt (storage-constrained devices)

Custom-built Tailscale binary for OpenWrt routers with limited flash storage. Uses the official OpenWrt init script and config with a stripped-down, UPX-compressed multicall binary.

## Target

- **Architecture:** aarch64_cortex-a53 (mediatek/filogic)
- **OpenWrt:** 25.12+
- **Binary size:** ~4.9MB (vs 9.2MB official package)

## What's included

| File | Source |
|---|---|
| `usr/sbin/tailscale.combined` | Custom-built multicall binary |
| `usr/sbin/tailscale` | Symlink → tailscale.combined |
| `usr/sbin/tailscaled` | Symlink → tailscale.combined |
| `usr/sbin/tailscale-update` | Update script |
| `etc/init.d/tailscale` | Official OpenWrt init script |
| `etc/config/tailscale` | Official OpenWrt UCI config |

## Features kept

- Subnet routes (advertise/use)
- Exit node (advertise/use)
- DNS / MagicDNS
- Tailscale SSH
- `tailscale serve` / `tailscale funnel`
- iptables/nftables firewall integration
- Netstack, port mapper, health checks
- Wake-on-LAN
- Logtail, client update capability

## Features stripped (not needed on a router)

AWS, cloud, Kubernetes, desktop (dbus, systray, NetworkManager), Synology, TPM, ACME, web client, QR codes, debug tools, doctor, taildrop, tailnet lock, app connectors, drive

## Install

On the router:

```bash
apk add kmod-tun
wget -O /tmp/ts-install.sh https://raw.githubusercontent.com/masarykadam/openwrt-tailscale-minimal/main/update.sh
sh /tmp/ts-install.sh
/etc/init.d/tailscale enable
tailscale up
```

To advertise your LAN as a subnet route:

```bash
tailscale up --advertise-routes=192.168.1.0/24
```

Then approve the subnet route in the Tailscale admin console (login.tailscale.com).

## Update

```bash
tailscale-update
```

### Auto-update (optional)

Add a weekly cron job on the router:

```bash
echo "0 4 * * 1 /usr/sbin/tailscale-update" >> /etc/crontabs/root
/etc/init.d/cron enable
/etc/init.d/cron restart
```

This checks every Monday at 4am. If there's a new version, it downloads and installs it.

## Build locally

### Prerequisites

- Go (`brew install go`)
- UPX (`brew install upx`)

### Build

```bash
./build.sh           # latest stable
./build.sh v1.96.5   # specific version
```

### Deploy manually

```bash
scp -O tailscale-openwrt.tgz root@192.168.1.1:/tmp/
# on router:
/etc/init.d/tailscale stop
tar x -zvC / -f /tmp/tailscale-openwrt.tgz
/etc/init.d/tailscale start
```

## CI/CD

GitHub Actions automatically checks for new Tailscale releases every Monday. If a new stable version is found, it builds and publishes a release.

You can also trigger a build manually from the Actions tab.

## Config

Settings are in `/etc/config/tailscale` on the router:

```
config settings 'settings'
    option log_stderr '1'
    option log_stdout '1'
    option port '41641'
    option state_file '/etc/tailscale/tailscaled.state'
    option fw_mode 'nftables'
```

## Credits

- [Tailscale](https://github.com/tailscale/tailscale)
- [OpenWrt tailscale package](https://github.com/openwrt/packages/tree/openwrt-25.12/net/tailscale) (init script and config)
- [openwrt-tailscale-enabler](https://github.com/adyanth/openwrt-tailscale-enabler) (inspiration)
- [OpenWrt wiki - storage constrained devices](https://openwrt.org/docs/guide-user/services/vpn/tailscale/start#installation_on_storage_constrained_devices)
