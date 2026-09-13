{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.virtualisation.distrobox;
in
{
  options.my.virtualisation.distrobox = {
    enable = mkEnableOption "Distrobox container environment with Podman";
  };

  config = mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };

    environment.systemPackages = [ pkgs.distrobox ];

    # host-spawn needs the Flatpak portal interface for xdg-open inside containers.
    services.flatpak.enable = true;

    # Expose the Nix store and profiles to containers.
    environment.etc."distrobox/distrobox.conf".text = ''
      container_additional_volumes="/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro /etc/static/profiles/per-user:/etc/static/profiles/per-user:ro"
    '';

    # Rootless podman needs subordinate UID/GID ranges.
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
