{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.core.distrobox;
in
{
  options.my.core.distrobox = {
    enable = mkEnableOption "Distrobox container environment with Podman";
  };

  config = mkIf cfg.enable {
    # Podman with Docker compatibility layer
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };

    # Distrobox CLI
    environment.systemPackages = [ pkgs.distrobox ];

    # Expose Nix store and profiles to containers by default
    environment.etc."distrobox/distrobox.conf".text = ''
      container_additional_volumes="/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro /etc/static/profiles/per-user:/etc/static/profiles/per-user:ro"
    '';

    # Podman rootless: allocate subordinate UID/GID ranges for the primary user
    users.users.${config.my.user.name} = {
      extraGroups = [ "podman" ];
      subUidRanges = [
        {
          startUid = 100000;
          count = 65536;
        }
      ];
      subGidRanges = [
        {
          startGid = 100000;
          count = 65536;
        }
      ];
    };
  };
}
