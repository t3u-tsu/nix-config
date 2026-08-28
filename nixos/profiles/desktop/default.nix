{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

{
  imports = [
    inputs.chaotic.nixosModules.nyx-overlay
  ];

  config = {
    nixpkgs.config.permittedInsecurePackages = [
      "ventoy-1.1.12"
    ];

    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    networking.networkmanager.enable = true;

    my = {
      user.extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "dialout"
      ];

      hardware.pc-tools.enable = true;

      services.desktop = {
        niri.enable = true;
        greetd.enable = true;
        pipewire.enable = true;
        gaming.enable = true;
        unity.enable = true;
        thunar.enable = true;
        fonts.enable = true;
      };

      # WCH-LinkE udev rules (defined in nixos/hardware/wch-linke.nix)
      hardware.dev-tools.wch-linke.enable = true;
    };

    # Integrate Home-manager desktop settings for the primary user
    home-manager.users.${config.my.user.name} = { config, pkgs, ... }: {
      imports = [
        ../../../home/desktop
      ];

      my.home.desktop = {
        browsers.enable = true;
        communication.enable = true;
        dev-tools.enable = true;
        gaming.enable = true;
        gpg-signing.enable = true;
        media.enable = true;
        creative.enable = true;
        theme.enable = true;
        xdg.enable = true;
        locales.enable = true;
        niri.enable = true;
      };
    };
  };
}
