{ pkgs, ... }:

{
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.fd.enable = true;
  programs.ripgrep.enable = true;
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.shellAliases = {
    ls = "eza";
    ll = "eza -l";
    la = "eza -a";
    tree = "eza --tree";
    cat = "bat";
    grep = "rg";
    sops = "SOPS_AGE_KEY=\$(ssh-to-age -private-key -i ~/.ssh/id_ed25519) sops";
  };
}
