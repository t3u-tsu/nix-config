{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Thunar configuration (Home-manager side)
  # System-wide services are needed for full functionality (gvfs, tumbler, xfconf)

  home = {
    packages = with pkgs; [
      file-roller # GUI Archive Manager required by thunar-archive-plugin
      unzip
      zip
      p7zip
    ];

    # Thunar's "Open Terminal Here" custom action. Passing --working-directory
    # forces ghostty to skip its single-instance mode (which would otherwise
    # ignore the working directory of a new launch) and open in the browsed
    # directory. %f is expanded shell-quoted by Thunar.
    file.".config/Thunar/uca.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
      <action>
      	<icon>utilities-terminal</icon>
      	<name>Open Terminal Here</name>
      	<submenu></submenu>
      	<unique-id>1774637027200592-1</unique-id>
      	<command>ghostty --working-directory=%f</command>
      	<description>Open a terminal in the current directory</description>
      	<range></range>
      	<patterns>*</patterns>
      	<startup-notify/>
      	<directories/>
      </action>
      </actions>
    '';

    # XFCE preferred-application helper. Kept for other integrations that use
    # exo-open --launch TerminalEmulator.
    file.".config/xfce4/helpers.rc".text = ''
      [Default]
      TerminalEmulator=ghostty
    '';
  };

  # Thunar settings via xfconf
  xfconf.settings = {
    thunar = {
      "misc-show-recent" = false;
    };
  };
}
