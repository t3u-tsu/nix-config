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
    gsts = ''for d in */; do [ -d "$d/.git" ] && (echo -e "\033[1;34m$(git -C "$d" rev-parse --show-toplevel)\033[0m" && git -C "$d" status && echo "---"); done'';
  };
}
