# Neovim Configuration (`home/desktop/dev-tools/neovim/`)

Modular and portable Neovim setup managed with Home Manager.

## Structure

- [default.nix](default.nix): Home Manager module declaring `my.home.desktop.dev-tools.neovim` options and linking Lua configuration.
- [config/](config/): Self-contained Neovim configuration directory, portable to non-Nix environments (`~/.config/nvim/`).
  - [config/init.lua](config/init.lua): Entry point.
  - [config/lua/config/options.lua](config/lua/config/options.lua): Core editor options.
  - [config/lua/config/theme.lua](config/lua/config/theme.lua): Vesper color palette highlights with Nix fallback.
