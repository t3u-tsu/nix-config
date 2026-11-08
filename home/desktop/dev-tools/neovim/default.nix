{
  config,
  lib,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools.neovim;
in
{
  options.my.home.desktop.dev-tools.neovim = {
    enable = lib.mkEnableOption "Neovim text editor";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      initLua = builtins.readFile ./config/init.lua;
    };

    xdg.configFile."nvim/lua".source = ./config/lua;
  };
}
