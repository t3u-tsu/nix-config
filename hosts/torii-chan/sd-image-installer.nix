{ pkgs, modulesPath, lib, ... }:

{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  # Disable SD image compression for faster build times and immediate flashing.
  sdImage.compressImage = false;

  # Write U-Boot to the image for Orange Pi Zero 3
  # Assumes ubootOrangePiZero3 is provided via Overlays in flake.nix
  sdImage.postBuildCommands = ''
    echo "Writing U-Boot to image..."
    dd if=${pkgs.ubootOrangePiZero3}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
  '';

  # Allow passwordless sudo for initial setup to prevent lockout before SOPS keys are deployed.
  security.sudo.wheelNeedsPassword = lib.mkForce false;

  # Allow root login via SSH for initial setup/deployment convenience.
  # This avoids 'trusted-users' issues when deploying the first configuration.
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
}
