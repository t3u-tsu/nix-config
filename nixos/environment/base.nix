{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.packages.core;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      file
      git
      just
      tmux
      vim
      which
    ];

    programs.zsh = {
      enable = true;
      enableGlobalCompInit = false;
      shellInit = ''
        export ZDOTDIR="''${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
      '';
    };
    users.defaultUserShell = pkgs.zsh;
  };
}
