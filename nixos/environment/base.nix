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

    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;
  };
}
