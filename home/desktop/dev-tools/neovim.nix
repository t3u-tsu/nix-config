{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.neovim;
  palette = import ../palette.nix;
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
        -- Vesper palette (Noctalia community Vesper), built from the shared
        -- palette.nix so a re-theme stays in one place. Applied directly because
        -- the Noctalia neovim template needs lazy.nvim / base16-colorscheme.
        local v = {
          bg = "${palette.bg}", bg2 = "${palette.bg2}", bg3 = "${palette.bg3}", dim = "${palette.dim}",
          fg = "${palette.fg}", fg2 = "${palette.fg2}",
          primary = "${palette.primary}", secondary = "${palette.secondary}", tertiary = "${palette.tertiary}",
          err = "${palette.err}",
        }
        local hi = function(g, o) vim.api.nvim_set_hl(0, g, o) end
        hi("Normal", { fg = v.fg, bg = v.bg })
        hi("NormalFloat", { fg = v.fg, bg = v.bg2 })
        hi("Comment", { fg = v.fg2 })
        hi("Identifier", { fg = v.primary })
        hi("Function", { fg = v.secondary })
        hi("Keyword", { fg = v.primary })
        hi("Statement", { fg = v.primary })
        hi("String", { fg = v.secondary })
        hi("Type", { fg = v.primary })
        hi("Constant", { fg = v.tertiary })
        hi("PreProc", { fg = v.tertiary })
        hi("Special", { fg = v.secondary })
        hi("Operator", { fg = v.fg2 })
        hi("Error", { fg = v.err })
        hi("LineNr", { fg = v.fg2 })
        hi("CursorLine", { bg = v.bg2 })
        hi("CursorLineNr", { fg = v.primary, bg = v.bg2 })
        hi("Visual", { bg = v.bg3 })
        hi("StatusLine", { bg = v.bg2, fg = v.fg })
        hi("StatusLineNC", { bg = v.bg, fg = v.fg2 })
        hi("WinSeparator", { fg = v.dim })
        hi("Pmenu", { bg = v.bg2, fg = v.fg })
        hi("PmenuSel", { bg = v.bg3, fg = v.primary })
        hi("TabLine", { bg = v.bg2, fg = v.fg2 })
        hi("TabLineSel", { bg = v.bg, fg = v.primary })
        hi("Search", { bg = v.primary, fg = "#0c0c0c" })
        hi("IncSearch", { bg = v.secondary, fg = "#0c0c0c" })
        hi("TelescopeNormal", { fg = v.fg, bg = v.bg })
        hi("TelescopeBorder", { fg = v.dim, bg = v.bg })
        hi("TelescopePromptTitle", { fg = v.bg, bg = v.primary })
        hi("TelescopePreviewTitle", { fg = v.bg, bg = v.secondary })
        hi("TelescopeResultsTitle", { fg = v.bg, bg = v.tertiary })
        hi("TelescopeSelection", { fg = v.fg, bg = v.bg3 })
        hi("TelescopeMatching", { fg = v.primary, bold = true })
        hi("NvimTreeNormal", { fg = v.fg, bg = v.bg })
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
