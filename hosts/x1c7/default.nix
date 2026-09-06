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

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "x1c7";

  services = {
    logind.settings.Login.HandleLidSwitchExternalPower = "lock";

    tlp.enable = true;

    fprintd.enable = true;
    fwupd.enable = true;
  };

  my.services.desktop = {
    greetd.greeterOutput.name = "eDP-1";
    bluetooth.experimental = true;
  };

  home-manager.users.${config.my.user.name} = {
    my.home.desktop = {
      noctalia.wallpaperPreset = "PTITSA";

      media.enable = true;
      dev-tools.ai-tools.enable = true;
    };
  };

  sops.secrets.x1c7_ssh_private_key = {
    path = "/home/${config.my.user.name}/.ssh/id_ed25519";
    owner = config.my.user.name;
    group = "users";
    mode = "0600";
  };
}
