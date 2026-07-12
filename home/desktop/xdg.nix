# home/desktop/xdg.nix - XDG user dirs + MIME associations via handlr
{
  config,
  lib,
  pkgs,
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
    # XDG User Directories to English names
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

    home.packages = [ pkgs.handlr-regex ];

    # Set default application handlers via handlr
    home.activation.setDefaultHandlers = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      DRY_RUN=${if config.home.enableDryRun or false then "echo" else ""}
      HANDLR="${pkgs.handlr-regex}/bin/handlr"

      # Browser (Zen)
      $DRY_RUN $HANDLR set text/html zen-beta.desktop
      $DRY_RUN $HANDLR set x-scheme-handler/http zen-beta.desktop
      $DRY_RUN $HANDLR set x-scheme-handler/https zen-beta.desktop
      $DRY_RUN $HANDLR set x-scheme-handler/about zen-beta.desktop
      $DRY_RUN $HANDLR set x-scheme-handler/unknown zen-beta.desktop

      # File manager
      $DRY_RUN $HANDLR set inode/directory thunar.desktop

      # PDF → Browser
      $DRY_RUN $HANDLR set application/pdf zen-beta.desktop

      # Text files → Neovim (wildcard covers all text/*)
      $DRY_RUN $HANDLR set 'text/*' nvim-ghostty.desktop

      # Images → Loupe (wildcard covers all image/*)
      $DRY_RUN $HANDLR set 'image/*' org.gnome.Loupe.desktop

      # Office documents → LibreOffice
      $DRY_RUN $HANDLR set application/vnd.openxmlformats-officedocument.spreadsheetml.sheet calc.desktop
      $DRY_RUN $HANDLR set application/vnd.ms-excel calc.desktop
      $DRY_RUN $HANDLR set text/csv calc.desktop
      $DRY_RUN $HANDLR set application/vnd.openxmlformats-officedocument.wordprocessingml.document writer.desktop
      $DRY_RUN $HANDLR set application/vnd.ms-word writer.desktop
      $DRY_RUN $HANDLR set application/vnd.openxmlformats-officedocument.presentationml.presentation impress.desktop
      $DRY_RUN $HANDLR set application/vnd.ms-powerpoint impress.desktop
    '';
  };
}
