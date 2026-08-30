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
    ./unity.nix
    ./fonts.nix
    ./thunar.nix
    ./graphics.nix
    ./networkmanager.nix
  ];

  options.my.services.desktop = {
    enable = mkEnableOption "Desktop system services (aggregate)";
  };

  config = mkIf cfg.enable {
    my = {
      services.desktop = {
        gaming.enable = mkDefault true;
        niri.enable = mkDefault true;
        greetd.enable = mkDefault true;
        pipewire.enable = mkDefault true;
        unity.enable = mkDefault true;
        fonts.enable = mkDefault true;
        thunar.enable = mkDefault true;
        graphics.enable = mkDefault true;
        networkmanager.enable = mkDefault true;
      };

      # Rootless podman + distrobox backing the Unity workflow (the external
      # unity module only enables podman; subuid/subgid ranges live here).
      virtualisation.distrobox.enable = mkDefault true;

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
