{
  config,
  lib,
  pkgs,
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

    # Zen claims text/html, the http(s)/about/unknown schemes, text/plain and
    # application/json through setAsDefaultBrowser, so only the non-browser
    # handlers belong here.
    home.activation.setDefaultHandlers = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      HANDLR="${pkgs.handlr-regex}/bin/handlr"

      run $HANDLR set inode/directory thunar.desktop

      run $HANDLR set application/pdf zen-beta.desktop

      run $HANDLR set text/plain nvim-ghostty.desktop
      run $HANDLR set application/json nvim-ghostty.desktop
      run $HANDLR set 'text/*' nvim-ghostty.desktop

      run $HANDLR set 'image/*' org.gnome.Loupe.desktop

      run $HANDLR set application/vnd.openxmlformats-officedocument.spreadsheetml.sheet calc.desktop
      run $HANDLR set application/vnd.ms-excel calc.desktop
      run $HANDLR set text/csv calc.desktop
      run $HANDLR set application/vnd.openxmlformats-officedocument.wordprocessingml.document writer.desktop
      run $HANDLR set application/vnd.ms-word writer.desktop
      run $HANDLR set application/vnd.openxmlformats-officedocument.presentationml.presentation impress.desktop
      run $HANDLR set application/vnd.ms-powerpoint impress.desktop
    '';
  };
}
