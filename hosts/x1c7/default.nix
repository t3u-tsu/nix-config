{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
    ../../nixos
    # throttled / tlp
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod;

    loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
    loader.efi.canTouchEfiVariables = true;
  };

  networking.hostName = "x1c7";

  # Power and thermal management lives in services/power.nix.
  services = {
    logind.settings.Login.HandleLidSwitchExternalPower = "lock";

    fprintd.enable = true;
    fwupd.enable = true;
  };

  # Enabled ahead of a possible LUKS migration; nothing on this host uses the
  # TPM yet.
  security.tpm2.enable = true;

  my.services.desktop = {
    greetd = {
      greeterOutput.name = "eDP-1";
      greeterWallpaper = "/home/${config.my.user.name}/Pictures/wallpapers/PTITSA/144133008_p0.jpg";
    };
    bluetooth.experimental = true;
  };

  home-manager.users.${config.my.user.name} = {
    my.home.desktop = {
      noctalia.wallpaperPreset = "PTITSA";

      media.enable = true;
      dev-tools.ai-tools.enable = true;
      dev-tools.hardware.enable = true;
    };
  };

  sops.secrets.x1c7_ssh_private_key = {
    path = "/home/${config.my.user.name}/.ssh/id_ed25519";
    owner = config.my.user.name;
    group = "users";
    mode = "0600";
  };
}
