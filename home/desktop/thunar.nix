{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.thunar;
in
{
  options.my.home.desktop.thunar = {
    enable = mkEnableOption "File manager";
  };

  config = mkIf cfg.enable {
    # gvfs / tumbler / xfconf come from the system module
    # (nixos/services/desktop/thunar.nix).

    home = {
      packages = with pkgs; [
        file-roller # GUI Archive Manager required by thunar-archive-plugin
        unzip
        zip
        p7zip
      ];

      # ghostty's single-instance mode ignores the working directory of a new
      # launch, so --working-directory is required here. Thunar quotes %f.
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

      # Read by integrations using `exo-open --launch TerminalEmulator`.
      file.".config/xfce4/helpers.rc".text = ''
        [Default]
        TerminalEmulator=ghostty
      '';
    };

    xfconf.settings = {
      thunar = {
        "misc-show-recent" = false;
      };
    };
  };
}
