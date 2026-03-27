# Niri Configuration

This directory manages the Niri scrollable-tiling Wayland compositor and its ecosystem, now fully unified with Noctalia Shell.

## 📂 Components

- **`default.nix`**: Core Niri settings, including layout, window rules, and keybindings (Omarchy + Vim style).
- **`noctalia/`**: Modularized configuration for `noctalia-shell` providing status bars, launchers, notifications, and OSD.
- **`addons.nix`**: Companion tools like `cliphist` and `nautilus`.
- **`power.nix`**: Power management and locking via Noctalia Shell IPC and `hypridle`.

## ⌨️ Keybindings Highlights

- `Mod + Return`: Terminal (Alacritty)
- `Mod + Shift + B`: Browser (Zen)
- `Mod + Space`: Launcher (Noctalia)
- `Mod + W`: Close window
- `Mod + H/J/K/L`: Navigation (Vim-style)
- `Mod + Arrow Keys`: Navigation (Standard)
- `Mod + V`: Toggle floating
- `Mod + Escape`: Session menu (Noctalia)
