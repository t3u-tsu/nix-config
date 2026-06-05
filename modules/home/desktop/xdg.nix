{
  config,
  lib,
  osConfig,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.xdg;
in
{
  options.my.home.desktop.xdg = {
    enable = mkEnableOption "XDG associations and desktop integration";
  };

  config = mkIf cfg.enable {
    # Force XDG User Directories to English names
    # Even if the locale is ja_JP.UTF-8, these directories should stay in English
    xdg.userDirs = {
      enable = true;
      createDirectories = true;

      download = "${config.home.homeDirectory}/Downloads";
      documents = "${config.home.homeDirectory}/Documents";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      desktop = "${config.home.homeDirectory}/Desktop";
      publicShare = "${config.home.homeDirectory}/Public";
      templates = "${config.home.homeDirectory}/Templates";
    };

    # Default Browser and File Associations (XDG)
    xdg.mimeApps = {
      enable = true;
      defaultApplications =
        let
          # MIME type mapping for better maintainability
          mimeMap = {
            "text/html" = "zen-beta.desktop";
            "x-scheme-handler/http" = "zen-beta.desktop";
            "x-scheme-handler/https" = "zen-beta.desktop";
            "x-scheme-handler/about" = "zen-beta.desktop";
            "x-scheme-handler/unknown" = "zen-beta.desktop";

            # File Browser (Thunar)
            "inode/directory" = "thunar.desktop";

            # Common file types
            "application/pdf" = "zen-beta.desktop";
            "image/png" = "org.gnome.Loupe.desktop";
            "image/jpeg" = "org.gnome.Loupe.desktop";
            "image/gif" = "org.gnome.Loupe.desktop";
            "image/svg+xml" = "zen-beta.desktop";
            "text/plain" = "nvim.desktop";

            # Office Documents (LibreOffice)
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop";
            "application/vnd.ms-excel" = "calc.desktop";
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
            "application/vnd.ms-word" = "writer.desktop";
            "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop";
            "application/vnd.ms-powerpoint" = "impress.desktop";
          };
        in
        mimeMap;
    };
  };
}
