# Neovim Configuration (`home/desktop/dev-tools/neovim/`)

Modular and portable Neovim setup managed with Home Manager.

## Structure

- [default.nix](default.nix): Home Manager module declaring `my.home.desktop.dev-tools.neovim` options and linking Lua configuration.
- [config/](config/): Self-contained Neovim configuration directory, portable to non-Nix environments (`~/.config/nvim/`).
  - [config/init.lua](config/init.lua): Entry point.
  - [config/lua/config/options.lua](config/lua/config/options.lua): Core editor options.
  - [config/lua/config/theme.lua](config/lua/config/theme.lua): Vesper color palette highlights with Nix fallback.
  - [config/lua/config/lazy.lua](config/lua/config/lazy.lua): `lazy.nvim` plugin manager bootstrap and configuration.
  - [config/lua/plugins/](config/lua/plugins/): Directory for plugin specifications (one file per plugin/tool).
    - [cmp.lua](config/lua/plugins/cmp.lua): Autocompletion engine (`nvim-cmp`) with LSP, buffer, path, and snippet sources.
    - [gitsigns.lua](config/lua/plugins/gitsigns.lua): Git diff signs in signcolumn and hunk actions (`]c`, `[c`, `<leader>h*`).
    - [lsp.lua](config/lua/plugins/lsp.lua): LSP configuration (`nil_ls`, `lua_ls`, `bashls`) with conditional startup and auto-format.
    - [lualine.lua](config/lua/plugins/lualine.lua): Statusline themed with Vesper palette.
    - [oil.lua](config/lua/plugins/oil.lua): Buffer-like file manager (`-` key).
    - [telescope.lua](config/lua/plugins/telescope.lua): Fuzzy finder for files, grep, and buffers (`<leader>f*`).
    - [treesitter.lua](config/lua/plugins/treesitter.lua): Tree-sitter syntax highlighting and indentation.
    - [ysh.lua](config/lua/plugins/ysh.lua): Oils / YSH syntax highlighting and filetype support (`oils.vim`).
