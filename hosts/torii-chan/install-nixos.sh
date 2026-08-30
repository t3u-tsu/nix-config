#!/usr/bin/env bash
# install-nixos - helper to install NixOS on a ConoHa VPS (512MB)
#
# Bundled with the installer ISO (hosts/torii-chan/vps-installer.nix); runs
# nixos-install non-interactively from an SSH session.
#
# Usage (run from the root shell after booting the ISO):
#   install-nixos network  manually configure networking
#                          (fallback when the static IP is not baked into the ISO)
#   install-nixos install  partition -> format -> swap -> nixos-install in one shot
#                          NOTE: wipes the disk, so INSTALL_YES=1 is mandatory
#   install-nixos status   show current network / memory / disk state
#
# Environment variables (all optional; defaults shown):
#   IFACE            network interface name (default: eth0)
#   IPV4             IPv4 address (e.g. 203.0.113.10)
#   PREFIX           IPv4 prefix length (default: 24)
#   GATEWAY          default gateway
#   NAMESERVERS      space-separated DNS (default: 1.1.1.1 8.8.8.8)
#   DISK             target disk (default: /dev/vda)
#   SWAP_SIZE        swap file size (default: 1G)
#   NIXOS_HOSTNAME   target hostname (default: conoha-vps)
#   SSH_PUBLIC_KEYS  public keys to register in authorizedKeys
#                    (one key per line; default: t3u's public key)
#
# Notes:
#   - Do not hardcode credentials or private keys (public keys only)
#   - This script is a minimal template for the target config. To install the
#     repo's flake config, include the closure in the ISO (isoImage.storeContents)
#     or use nixos-install --flake (see hosts/torii-chan/README.md)
set -euo pipefail

IFACE="${IFACE:-eth0}"
IPV4="${IPV4:-}"
PREFIX="${PREFIX:-24}"
GATEWAY="${GATEWAY:-}"
NAMESERVERS="${NAMESERVERS:-1.1.1.1 8.8.8.8}"
DISK="${DISK:-/dev/vda}"
SWAP_SIZE="${SWAP_SIZE:-1G}"
NIXOS_HOSTNAME="${NIXOS_HOSTNAME:-conoha-vps}"
SSH_PUBLIC_KEYS="${SSH_PUBLIC_KEYS:-ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

# --- network: manually configure a static IP (fallback) -----------------------
cmd_network() {
  [ -n "$IPV4" ] || die "IPV4 is not set. Example: IPV4=203.0.113.10 GATEWAY=203.0.113.1 install-nixos network"
  [ -n "$GATEWAY" ] || die "GATEWAY is not set."

  echo "==> Checking interface: $IFACE"
  ip link show "$IFACE" >/dev/null 2>&1 \
    || die "interface $IFACE not found (check the real name with ip link)"

  echo "==> Setting static IP: $IPV4/$PREFIX"
  ip addr flush dev "$IFACE"
  ip addr add "$IPV4/$PREFIX" dev "$IFACE"
  ip link set "$IFACE" up

  echo "==> Setting default route: via $GATEWAY"
  # Also try onlink in case the gateway is not in the same subnet
  ip route replace default via "$GATEWAY" dev "$IFACE" onlink \
    || die "failed to set the default route"

  echo "==> Configuring DNS"
  : > /etc/resolv.conf
  for ns in $NAMESERVERS; do
    echo "nameserver $ns" >> /etc/resolv.conf
  done

  echo "==> Checking connectivity"
  if ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
    echo "OK: internet reachable"
  else
    echo "warning: ping to 1.1.1.1 failed (check the network configuration)"
  fi
  echo "==> Network configuration complete"
}

# --- status: show the current state -------------------------------------------
cmd_status() {
  echo "==> Interfaces / IP"
  ip -brief addr 2>/dev/null || ip addr
  echo ""
  echo "==> Routing"
  ip route
  echo ""
  echo "==> Memory / swap"
  free -h
  echo ""
  echo "==> zram"
  zramctl 2>/dev/null || echo "zram is not available"
  echo ""
  echo "==> Disks"
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
}

# --- install: partition -> format -> swap -> nixos-install --------------------
cmd_install() {
  [ "${INSTALL_YES:-}" = "1" ] \
    || die "This will wipe $DISK. Set INSTALL_YES=1 to proceed"

  [ -b "$DISK" ] || die "disk not found: $DISK (check the device name with lsblk)"
  ROOT_PART="${DISK}1"

  echo "==> Partitioning (MBR / BIOS boot): $DISK"
  parted -s "$DISK" mklabel msdos
  parted -s "$DISK" mkpart primary ext4 1MiB 100%
  parted -s "$DISK" set 1 boot on
  partprobe "$DISK"
  sleep 2 # wait for the kernel to see the new partition

  echo "==> Formatting: $ROOT_PART (ext4)"
  mkfs.ext4 -F -L nixos "$ROOT_PART"

  echo "==> Mounting /mnt"
  mount "$ROOT_PART" /mnt

  echo "==> Creating swap file: /mnt/swapfile (${SWAP_SIZE})"
  # Doubles as the target's swap while also absorbing low-memory on the live
  # environment (tmpfs /nix/store), so swapon before nixos-install
  fallocate -l "$SWAP_SIZE" /mnt/swapfile
  chmod 600 /mnt/swapfile
  mkswap /mnt/swapfile
  swapon /mnt/swapfile

  echo "==> Generating hardware config (nixos-generate-config)"
  nixos-generate-config --root /mnt

  echo "==> Writing configuration.nix"
  write_configuration

  echo "==> Running nixos-install (no root password; login via SSH key)"
  nixos-install --no-root-passwd --root /mnt

  echo ""
  echo "==> Installation complete. Next steps:"
  echo "    1. Disable swap and unmount the disk"
  echo "       swapoff /mnt/swapfile && umount /mnt"
  echo "    2. Eject the ISO and reboot from the local machine"
  echo "       ./terraform/scripts/nixos-iso.sh eject <instance_id>"
}

# --- generate configuration.nix (called from install) -------------------------
write_configuration() {
  # Build the Nix list string of authorizedKeys (one key per line)
  local nix_keys=""
  while IFS= read -r key; do
    [ -n "$key" ] && nix_keys="${nix_keys} \"${key}\""
  done <<< "${SSH_PUBLIC_KEYS}"

  # Build the Nix list string of nameservers
  local nix_ns=""
  for ns in $NAMESERVERS; do
    nix_ns="${nix_ns} \"${ns}\""
  done

  cat > /mnt/etc/nixos/configuration.nix <<EOF
# Minimal NixOS config for a ConoHa VPS (generated by install-nixos.sh)
{
  imports = [
    ./hardware-configuration.nix
  ];

  # GRUB (BIOS / MBR)
  boot.loader.grub = {
    enable = true;
    devices = [ "${DISK}" ];
  };

  networking.hostName = "${NIXOS_HOSTNAME}";
  networking.usePredictableInterfaceNames = false; # use the virtio NIC as eth0

  # ConoHa VPS does not provide DHCP, so use a static IP
  networking.useDHCP = false;
  networking.interfaces.eth0.ipv4.addresses = [
    { address = "${IPV4}"; prefixLength = ${PREFIX}; }
  ];
  networking.defaultGateway = "${GATEWAY}";
  networking.nameservers = [${nix_ns} ];

  # SSH (root logs in with a public key only)
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication= [redacted]
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [${nix_keys} ];

  # Enable the swap file created during installation
  swapDevices = [
    { device = "/swapfile"; }
  ];

  system.stateVersion = "26.05";
}
EOF

  echo "    Generated config: /mnt/etc/nixos/configuration.nix"
  sed -n '1,60p' /mnt/etc/nixos/configuration.nix
}

# --- main ----------------------------------------------------------------------
cmd="${1:-help}"
case "${cmd}" in
  network)
    cmd_network
    ;;
  install)
    cmd_install
    ;;
  status)
    cmd_status
    ;;
  help | -h | --help)
    cat <<'HELP'
install-nixos - helper to install NixOS on a ConoHa VPS (512MB)

Usage:
  install-nixos network  manually configure networking
                        (fallback when the static IP is not baked into the ISO)
  install-nixos install  partition -> format -> swap -> nixos-install in one shot
                        NOTE: wipes the disk, so INSTALL_YES=1 is mandatory
  install-nixos status   show network / memory / disk state

Environment variables (all optional; defaults shown):
  IFACE            network interface name (default: eth0)
  IPV4             IPv4 address (e.g. 203.0.113.10)
  PREFIX           IPv4 prefix length (default: 24)
  GATEWAY          default gateway
  NAMESERVERS      space-separated DNS (default: 1.1.1.1 8.8.8.8)
  DISK             target disk (default: /dev/vda)
  SWAP_SIZE        swap file size (default: 1G)
  NIXOS_HOSTNAME   target hostname (default: conoha-vps)
  SSH_PUBLIC_KEYS  public keys to register in authorizedKeys (one key per line)

Details: hosts/torii-chan/README.md
HELP
    ;;
  *)
    echo "usage: install-nixos {network|install|status|help}" >&2
    exit 1
    ;;
esac