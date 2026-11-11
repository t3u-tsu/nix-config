{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools.neovim;
  palette = import ../../../../lib/palette.nix;
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
      extraPackages = with pkgs; [
        gcc
        lua-language-server
        tree-sitter
      ];
      initLua = ''
        vim.g.nix_palette = {
          bg = "${palette.bg}",
          bg2 = "${palette.bg2}",
          bg3 = "${palette.bg3}",
          dim = "${palette.dim}",
          fg = "${palette.fg}",
          fg2 = "${palette.fg2}",
          primary = "${palette.primary}",
          secondary = "${palette.secondary}",
          tertiary = "${palette.tertiary}",
          err = "${palette.err}",
        }
      ''
      + builtins.readFile ./config/init.lua;
    };

    xdg.configFile."nvim/lua".source = ./config/lua;
  };
}
