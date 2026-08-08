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
    ../../services/desktop
    ../../services/desktop/fonts.nix
    # Chaotic-Nyx overlay: provides bleeding-edge packages used by desktop
    # (e.g. gamescope_git, mangohud_git in home/desktop/gaming.nix).
    # The binary cache is NOT imported here: it is managed manually in
    # nixos/base/nix.nix (keeps chaotic-nyx at the lowest priority tier).
    inputs.chaotic.nixosModules.nyx-overlay
  ];

  config = {
    nixpkgs.config.permittedInsecurePackages = [
      "ventoy-1.1.12"
    ];

    # Desktop hardware: redistributable firmware (Wi-Fi/BT/GPU) and graphics
    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    # Desktop networking (NetworkManager)
    networking.networkmanager.enable = true;

    my = {
      # NOTE: keep "wheel" here — setting user.extraGroups replaces the base
      # default ([ "wheel" ] in nixos/base/user.nix), so omitting it removes
      # sudo access for the primary user.
      user.extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "dialout"
      ];

      hardware.pc-tools.enable = true;

      # System-wide desktop services
      services.desktop = {
        niri.enable = true;
        greetd.enable = true;
        pipewire.enable = true;
        gaming.enable = true;
      };

      # WCH-LinkE udev rules (defined in nixos/hardware/wch-linke.nix)
      hardware.dev-tools.wch-linke.enable =
        config.home-manager.users.${config.my.user.name}.my.home.desktop.dev-tools.hardware.enable;
    };

    # Integrate Home-manager desktop settings for the primary user
    home-manager.users.${config.my.user.name} = { config, pkgs, ... }: {
      # gh credential helper is configured in home/desktop/dev-tools/git-tools.nix
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
