{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    bat = {
      enable = true;
      config = {
        pager = "less -FR";
      };
      extraPackages = with pkgs.bat-extras; [
        batman
        batdiff
      ];
    };

    eza = {
      enable = true;
      enableZshIntegration = true;
      icons = "auto";
      colors = "auto";
      git = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f --strip-cwd-prefix --hidden --exclude .git";
      fileWidgetCommand = "fd --type f --strip-cwd-prefix --hidden --exclude .git";
      changeDirWidgetCommand = "fd --type d --strip-cwd-prefix --hidden --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
      ];
    };

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
  };

  home.sessionVariables = {
    EDITOR = lib.mkDefault "vim";
    VISUAL = lib.mkDefault "vim";
  };
}
