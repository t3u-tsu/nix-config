{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.bitwarden;
  autostart = pkgs.writeText "bitwarden.desktop" ''
    [Desktop Entry]
    Type=Application
    Name=Bitwarden
    Comment=Bitwarden startup script
    Exec=${pkgs.bitwarden-desktop}/bin/bitwarden --autostart
    StartupNotify=false
    Terminal=false
  '';
in
{
  options.my.home.desktop.bitwarden = {
    enable = lib.mkEnableOption "Bitwarden desktop autostart entry";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.bitwarden-desktop
      pkgs.bitwarden-cli
    ];
    # The app rewrites this entry with the store path of whichever build it was
    # launched from, so a path from an older generation survives flake updates
    # and can be collected. Writing through a home.file symlink would fail with
    # EROFS instead.
    home.activation.bitwardenAutostart = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD install -Dm644 ${autostart} "$HOME/.config/autostart/bitwarden.desktop"
    '';
  };
}
