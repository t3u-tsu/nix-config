{
  lib,
  ...
}:

{
  programs = {
    bat.enable = true;
    eza.enable = true;
    fzf.enable = true;
    zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
    };
    fd.enable = true;
    ripgrep.enable = true;
    yazi = {
      enable = true;
      enableZshIntegration = true;
    };
    tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  home = {
    sessionVariables = {
      EDITOR = lib.mkDefault "vim";
      VISUAL = lib.mkDefault "vim";
    };
    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -a";
      da = "direnv allow";
    };
  };
}
