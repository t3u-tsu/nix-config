{
  config,
  lib,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools.neovim;
  palette = import ../../../lib/palette.nix;
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

      extraConfig = ''
        lua << EOF
        -- Vesper palette from palette.nix; Noctalia's neovim template needs
        -- lazy.nvim / base16-colorscheme, so the highlight groups are set here.
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
        hi("Search", { bg = v.primary, fg = v.bg })
        hi("IncSearch", { bg = v.secondary, fg = v.bg })
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
  };
}
