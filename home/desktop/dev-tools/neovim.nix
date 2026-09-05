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
        local colors_file = os.getenv("HOME") .. "/.config/nvim/lua/matugen.lua"
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

    # Note: xdg.desktopEntries is broken in the current home-manager (the
    # removed `extraConfig` option is evaluated for every entry), so the
    # .desktop file is shipped directly via xdg.dataFile instead.
    xdg.dataFile."applications/nvim-ghostty.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Neovim (Ghostty)
      GenericName=Text Editor
      Comment=Edit text files in Neovim inside Ghostty
      Exec=ghostty -e nvim %F
      Icon=nvim
      Terminal=false
      Categories=Utility;TextEditor;Development;
      MimeType=text/plain;text/markdown;text/x-shellscript;text/x-python;text/x-go;text/x-rust;text/x-c;text/x-c++;application/json;application/javascript;application/xml;text/css;text/x-yaml;text/x-toml;text/x-nix;text/x-lua;text/x-log;text/x-ini;text/x-properties;text/x-makefile;text/x-dockerfile;text/x-sql;text/x-typescript;text/x-ruby;text/x-perl;
    '';
  };
}
