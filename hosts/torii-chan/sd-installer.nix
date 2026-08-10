# hosts/torii-chan/sd-installer.nix - SD installer image for the Orange Pi Zero3
#
# stage: installer SD card image (no production services, SSH via temporary password).
# Redesigned from the old sd-image-installer.nix around installer-common.nix
# (shared with the VPS installer). Solely for provisioning the production SD
# (torii-chan-sd) or production HDD (torii-chan-hdd); Nebula / DDNS / NAT are not run.
#
# Build (temporary password auto-issued):
#   ./hosts/torii-chan/build-sd-image.sh
{
  pkgs,
  modulesPath,
  lib,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
    ./installer-common.nix
  ];

  # Disable SD image compression for faster build times and immediate flashing.
  sdImage.compressImage = false;

  # Silence ZFS evaluation warning for the installer image
  boot.zfs.forceImportRoot = false;

  # Write U-Boot to the image for Orange Pi Zero3
  # Assumes ubootOrangePiZero3 is provided via Overlays in flake.nix
  sdImage.postBuildCommands = ''
    echo "Writing U-Boot to image..."
    dd if=${pkgs.ubootOrangePiZero3}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
  '';

  # --- SBC installer: LAN-only provisioning ---
  # Temporary password + password auth allowed ("loose") so you can SSH in and
  # work right after flashing. Networking uses the static IP from sbc.nix
  # (192.168.0.128). The firewall only opens port 22 (plain LAN state, unrelated
  # to the production nebula0 restrictions).
  my.installer = {
    enable = true;
    # LAN-only, so allow login with the temporary password (the VPS installer is key-only)
    allowPasswordAuthentication = true;
    firewallOpenPorts = [ 22 ];
  };
}
