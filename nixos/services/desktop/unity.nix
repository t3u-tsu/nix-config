{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.my.services.desktop.unity;
in
{
  # Upstream module: installs podman + distrobox and enables rootless podman.
  imports = [
    inputs.unity-via-distrobox.nixosModules.unity
  ];

  options.my.services.desktop.unity = {
    enable = lib.mkEnableOption "Unity Hub & Unity Editor via Distrobox";
  };

  config = lib.mkIf cfg.enable {
    services.unity-via-distrobox.enable = true;
  };
}
