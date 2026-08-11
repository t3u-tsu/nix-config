{
  config,
  lib,
  inputs,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.unity;
in
{
  # Upstream unity-via-distrobox-flake NixOS module:
  # installs podman + distrobox and enables rootless podman.
  imports = [
    inputs.unity-via-distrobox.nixosModules.unity
  ];

  options.my.services.desktop.unity = {
    enable = mkEnableOption "Unity Hub & Unity Editor via Distrobox";
  };

  config = mkIf cfg.enable {
    services.unity-via-distrobox.enable = true;
  };
}
