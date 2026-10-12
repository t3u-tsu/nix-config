{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.packages.core;
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      file
      ghostty.terminfo
      git
      tmux
      vim
      which
    ];

    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;
  };
}
