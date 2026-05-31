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
    environment.enableAllTerminfo = true;

    environment.systemPackages = with pkgs; [
      curl
      file
      git
      ghostty.terminfo
      tmux
      vim
      wget
      which
    ];

    # Zsh configuration via NixOS (System-wide)
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;
  };
}
