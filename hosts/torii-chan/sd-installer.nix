# Installer SD card image for the Orange Pi Zero3: provisions the production SD
# (torii-chan-sd) or HDD (torii-chan-hdd) config, so no production services run.
# Shares installer-common.nix with the VPS installer ISO; the temporary password
# is only valid in the live environment (build via ./build-sd-image.sh).
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

  # Uncompressed: faster to build and flash
  sdImage.compressImage = false;

  # Silence the ZFS evaluation warning for the installer image
  boot.zfs.forceImportRoot = false;

  # ubootOrangePiZero3 comes from an overlay in flake.nix
  sdImage.postBuildCommands = ''
    echo "Writing U-Boot to image..."
    dd if=${pkgs.ubootOrangePiZero3}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
  '';

  my.installer = {
    enable = true;
    # LAN-only (static 192.168.0.128 from sbc.nix), so the temporary password is
    # allowed; the VPS installer is key-only.
    allowPasswordAuthentication = true;
    firewallOpenPorts = [ 22 ];
  };
}
