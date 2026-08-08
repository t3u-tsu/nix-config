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
      git
      tmux
      vim
      which
    ];

    # Zsh configuration via NixOS (System-wide)
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;
  };
}
