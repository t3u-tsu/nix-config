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
    thunar
    thunar-archive-plugin
    thunar-volman
  ];

  # Thunar settings via xfconf
  xfconf.settings = {
    thunar = {
      "misc-show-recent" = false;
    };
  };

  # File associations (Handled globally or per-app)
  xdg.mimeApps.defaultApplications = {
    "inode/directory" = "thunar.desktop";
  };
}
