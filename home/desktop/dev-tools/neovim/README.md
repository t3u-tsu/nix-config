# Neovim Configuration (`home/desktop/dev-tools/neovim/`)

Modular and portable Neovim setup managed with Home Manager.

## Modules

| File | Description | Options |
| :--- | :--- | :--- |
| [default.nix](default.nix) | Home Manager module linking Lua configuration and injecting `vim.g.nix_palette`. | `my.home.desktop.dev-tools.neovim.enable`, `my.home.desktop.dev-tools.neovim.julia.enable` |
| [config/init.lua](config/init.lua) | Entry point for the portable Neovim configuration (`~/.config/nvim/`). | Loaded by `programs.neovim` |
| [config/lua/config/options.lua](config/lua/config/options.lua) | Core editor options. | Loaded by [config/init.lua](config/init.lua) |
| [config/lua/config/theme.lua](config/lua/config/theme.lua) | Vesper color palette highlights with Nix fallback. | Loaded by [config/init.lua](config/init.lua) |
| [config/lua/config/lazy.lua](config/lua/config/lazy.lua) | `lazy.nvim` plugin manager bootstrap and configuration. | Loaded by [config/init.lua](config/init.lua) |
| [config/after/ftplugin/julia.lua](config/after/ftplugin/julia.lua) | Julia buffer-local settings (4-space indentation, `!` in `iskeyword`). | Loaded for `julia` filetype |
| [config/after/indent/julia.lua](config/after/indent/julia.lua) | Julia Tree-sitter indentation override. | Loaded for `julia` filetype |
| [config/lua/plugins/cmp.lua](config/lua/plugins/cmp.lua) | Autocompletion engine (`nvim-cmp`) with LSP, buffer, path, snippet, and Julia LaTeX symbol sources. | `lazy.nvim` plugin spec |
| [config/lua/plugins/direnv.lua](config/lua/plugins/direnv.lua) | Direnv integration (`direnv.vim`) for automatic environment switching. | `lazy.nvim` plugin spec |
| [config/lua/plugins/gitsigns.lua](config/lua/plugins/gitsigns.lua) | Git diff signs in signcolumn and hunk actions (`]c`, `[c`, `<leader>h*`). | `lazy.nvim` plugin spec |
| [config/lua/plugins/lsp.lua](config/lua/plugins/lsp.lua) | LSP configuration (`nil_ls`, `lua_ls`, `bashls`, `perlnavigator`, `tinymist`, `julials`) with conditional startup, direnv reload, and auto-format. Requires `LanguageServer.jl` for `julials` (see below). | `lazy.nvim` plugin spec |
| [config/lua/plugins/lualine.lua](config/lua/plugins/lualine.lua) | Statusline themed with Vesper palette. | `lazy.nvim` plugin spec |
| [config/lua/plugins/oil.lua](config/lua/plugins/oil.lua) | Buffer-like file manager (`-` key). | `lazy.nvim` plugin spec |
| [config/lua/plugins/telescope.lua](config/lua/plugins/telescope.lua) | Fuzzy finder for files, grep, and buffers (`<leader>f*`). | `lazy.nvim` plugin spec |
| [config/lua/plugins/treesitter.lua](config/lua/plugins/treesitter.lua) | Tree-sitter syntax highlighting and indentation. | `lazy.nvim` plugin spec |
| [config/lua/plugins/typst.lua](config/lua/plugins/typst.lua) | Typst live preview (`typst-preview.nvim`) with tinymist integration (`<leader>tp`). | `lazy.nvim` plugin spec |
| [config/lua/plugins/ysh.lua](config/lua/plugins/ysh.lua) | Oils / YSH syntax highlighting and filetype support (`oils.vim`). | `lazy.nvim` plugin spec |

## Julia LSP Setup

When `my.home.desktop.dev-tools.neovim.julia.enable` is enabled (defaults to `my.home.desktop.dev-tools.julia.enable`), Home Manager installs the patched `tree-sitter-julia` parser (`nvim/parser/julia.so` with `u"..."` juxtaposition support), provisions `LanguageServer.jl` into `~/.julia/environments/nvim-lspconfig`, and provides `julia-lsp-build-sysimage`.

Outside NixOS/Home Manager, install `LanguageServer.jl` manually:

```sh
julia --project=~/.julia/environments/nvim-lspconfig -e 'using Pkg; Pkg.add("LanguageServer"); Pkg.precompile()'
```

To speed up `julials` startup, build a sysimage (`~/.julia/environments/nvim-lspconfig/languageserver.so`) with `julia-lsp-build-sysimage`. When present, `julials` automatically passes `--sysimage=<path>` and falls back to default startup otherwise.

## References

- Development tools index: [home/desktop/dev-tools/](../README.md)
- Palette definitions: [lib/palette.nix](../../../../lib/palette.nix)
