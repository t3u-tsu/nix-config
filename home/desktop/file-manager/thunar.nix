{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Thunar configuration (Home-manager side)
  # System-wide services are needed for full functionality (gvfs, tumbler, xfconf)

  home.packages = with pkgs; [
    file-roller # GUI Archive Manager required by thunar-archive-plugin
    unzip
    zip
    p7zip
  ];

  # Thunar settings via xfconf
  xfconf.settings = {
    thunar = {
      "misc-show-recent" = false;
    };
  };

  # XFCE preferred-application helpers. `TerminalEmulator` is what
  # `exo-open --launch TerminalEmulator` (Thunar's "Open Terminal Here"
  # custom action) uses, and resolves ghostty as the terminal.
  home.file.".config/xfce4/helpers.rc".text = ''
    [Default]
    TerminalEmulator=ghostty
  '';
}
