{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop;
in
{
  imports = [
    ./gaming.nix
    ./niri.nix
    ./greetd.nix
    ./pipewire.nix
    ./bluetooth.nix
    ./unity.nix
    ./fonts.nix
    ./thunar.nix
    ./graphics.nix
    ./networkmanager.nix
    ./chromium.nix
  ];

  options.my.services.desktop = {
    enable = mkEnableOption "Desktop system services (lightweight core)";

    full = {
      enable = mkEnableOption "Full desktop system services (gaming, Unity/Distrobox)";
    };
  };

  config = mkIf cfg.enable {
    my = {
      services.desktop = {
        # Lightweight core: any desktop machine
        niri.enable = mkDefault true;
        greetd.enable = mkDefault true;
        pipewire.enable = mkDefault true;
        thunar.enable = mkDefault true;
        graphics.enable = mkDefault true;
        networkmanager.enable = mkDefault true;
        bluetooth.enable = mkDefault true;
        fonts.enable = mkDefault true;
        chromium.enable = mkDefault true;

        # Heavy extras: opt-in via my.services.desktop.full.enable
        gaming.enable = mkDefault cfg.full.enable;
        unity.enable = mkDefault cfg.full.enable;
      };

      # Rootless podman + distrobox backing the Unity workflow (the external
      # unity module only enables podman; subuid/subgid ranges live here).
      virtualisation.distrobox.enable = mkDefault cfg.full.enable;

      # Standard desktop user groups
      user.extraGroups = mkDefault [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "dialout"
      ];
    };
  };
}
