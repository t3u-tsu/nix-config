{ config, lib, osConfig, ... }:

with lib;
let
  cfg = config.my.home.desktop.xdg;
in {
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

    # Default Browser (XDG)
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "zen.desktop";
        "x-scheme-handler/http" = "zen.desktop";
        "x-scheme-handler/https" = "zen.desktop";
        "x-scheme-handler/about" = "zen.desktop";
        "x-scheme-handler/unknown" = "zen.desktop";
      };
    };

    # Default Terminal Environment Variable
    home.sessionVariables.TERMINAL = "alacritty";

    # KDE Default Terminal Configuration (Fallback)
    home.file.".config/kdeglobals".text = ''
      [General]
      TerminalApplication=alacritty
      TerminalService=Alacritty.desktop
    '';
  };
}
