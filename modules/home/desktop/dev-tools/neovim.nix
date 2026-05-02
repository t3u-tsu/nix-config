{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.neovim;
in
{
  options.my.home.desktop.dev-tools.neovim = {
    enable = mkEnableOption "Neovim text editor";
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;

      extraConfig = ''
        lua << EOF
        local colors_file = os.getenv("HOME") .. "/.cache/noctalia/neovim-colors.lua"
        local f = io.open(colors_file, "r")
        if f then
          f:close()
          local colors = dofile(colors_file)
          -- Simple color application (mocking noctalia.nvim behavior)
          vim.api.nvim_set_hl(0, "Normal", { fg = colors.on_surface, bg = colors.surface })
          vim.api.nvim_set_hl(0, "Identifier", { fg = colors.primary })
          vim.api.nvim_set_hl(0, "Function", { fg = colors.secondary })
        end
        EOF
      '';
    };
  };
}
