{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.browsers.bitwarden;
  manifest = pkgs.writeText "com.8bit.bitwarden.json" (
    builtins.toJSON {
      name = "com.8bit.bitwarden";
      description = "Bitwarden desktop <-> browser bridge";
      path = "${pkgs.bitwarden-desktop}/libexec/desktop_proxy";
      type = "stdio";
      allowed_extensions = [ "{446900e4-71c2-419f-a6a7-df9c091e268b}" ];
    }
  );
in
{
  options.my.home.desktop.browsers.bitwarden = {
    enable = mkEnableOption "Bitwarden browser integration (Firefox/Zen native messaging host)";
  };

  config = mkIf cfg.enable {
    # Zen has no ~/.mozilla/firefox profile, so the desktop app will not create
    # this manifest for it. The app does rewrite it when present, and a home.file
    # symlink into the read-only store makes that rewrite fail with EROFS, which
    # aborts the native-messaging setup before it creates the IPC socket.
    home.activation.bitwardenNativeMessaging = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD install -Dm644 ${manifest} "$HOME/.mozilla/native-messaging-hosts/com.8bit.bitwarden.json"
    '';
  };
}
