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
    - [lsp.lua](config/lua/plugins/lsp.lua): LSP configuration (`nil_ls`, `lua_ls`, `bashls`) with conditional startup and auto-format.
    - [oil.lua](config/lua/plugins/oil.lua): Buffer-like file manager (`-` key).
    - [telescope.lua](config/lua/plugins/telescope.lua): Fuzzy finder for files, grep, and buffers (`<leader>f*`).
    - [treesitter.lua](config/lua/plugins/treesitter.lua): Tree-sitter syntax highlighting and indentation.
