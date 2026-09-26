{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.browsers.bitwarden;
in
{
  options.my.home.desktop.browsers.bitwarden = {
    enable = mkEnableOption "Bitwarden browser integration (Firefox/Zen native messaging host)";
  };

  config = mkIf cfg.enable {
    # Zen reads ~/.mozilla/native-messaging-hosts, but the desktop app only
    # writes there when it finds a ~/.mozilla/firefox profile, which Zen lacks.
    home.file.".mozilla/native-messaging-hosts/com.8bit.bitwarden.json".text = builtins.toJSON {
      name = "com.8bit.bitwarden";
      description = "Bitwarden desktop <-> browser bridge";
      path = "${pkgs.bitwarden-desktop}/libexec/desktop_proxy";
      type = "stdio";
      allowed_extensions = [ "{446900e4-71c2-419f-a6a7-df9c091e268b}" ];
    };
  };
}
