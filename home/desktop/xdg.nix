{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.xdg;
in
{
  options.my.home.desktop.xdg = {
    enable = lib.mkEnableOption "XDG associations and desktop integration";
  };

  config = lib.mkIf cfg.enable {
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

    home.packages = [
      pkgs.handlr-regex
      pkgs.xdg-terminal-exec
    ];

    # FreeDesktop Default Terminal Execution Specification
    xdg.configFile."xdg-terminals.list".text = ''
      com.mitchellh.ghostty.desktop
    '';

    # Zen no longer sets xdg.mimeApps (inactive when xdg.mimeApps.enable is
    # false and conflicts with handlr), so browser HTTP/HTML handlers are
    # declared here with handlr while Zen sets $BROWSER.
    home.activation.setDefaultHandlers = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      HANDLR="${pkgs.handlr-regex}/bin/handlr"

      run $HANDLR set inode/directory thunar.desktop

      run $HANDLR set application/pdf sioyek.desktop

      run $HANDLR set text/markdown marktext.desktop

      run $HANDLR set x-scheme-handler/http zen-beta.desktop
      run $HANDLR set x-scheme-handler/https zen-beta.desktop
      run $HANDLR set x-scheme-handler/about zen-beta.desktop
      run $HANDLR set x-scheme-handler/unknown zen-beta.desktop
      run $HANDLR set text/html zen-beta.desktop

      run $HANDLR set text/plain nvim.desktop
      run $HANDLR set application/json nvim.desktop
      run $HANDLR set 'text/*' nvim.desktop

      run $HANDLR set 'image/*' swayimg.desktop

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
