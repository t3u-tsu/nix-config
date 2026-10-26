{
  config,
  inputs,
  lib,
  ...
}:

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
    enable = lib.mkEnableOption "Desktop system services (lightweight core)";

    full = {
      enable = lib.mkEnableOption "Full desktop system services (gaming, Unity/Distrobox)";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.nur.overlays.default
    ];

    my = {
      services.desktop = {
        niri.enable = lib.mkDefault true;
        greetd.enable = lib.mkDefault true;
        pipewire.enable = lib.mkDefault true;
        thunar.enable = lib.mkDefault true;
        graphics.enable = lib.mkDefault true;
        networkmanager.enable = lib.mkDefault true;
        bluetooth.enable = lib.mkDefault true;
        fonts.enable = lib.mkDefault true;
        chromium.enable = lib.mkDefault true;

        gaming.enable = lib.mkDefault cfg.full.enable;
        unity.enable = lib.mkDefault cfg.full.enable;
      };

      # Rootless podman + distrobox backing the Unity workflow (the external
      # unity module only enables podman; subuid/subgid ranges live here).
      virtualisation.distrobox.enable = lib.mkDefault cfg.full.enable;

      user.extraGroups = [
        "networkmanager"
        "video"
        "render"
        "audio"
        "gamemode"
      ];
    };
  };
}
