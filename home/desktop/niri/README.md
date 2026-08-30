# Niri Configuration

This directory manages the Niri scrollable-tiling Wayland compositor and its ecosystem, unified with Noctalia Shell.

## Components

- **`default.nix`**: Core Niri settings (layout, window rules, keybindings), Noctalia Shell integration (status bars, launchers, notifications, OSD), companion tools (`cliphist`), and power management via Noctalia IPC + `hypridle`.

## Keybindings Highlights

- `Mod + Return`: Terminal
- `Mod + Shift + B`: Browser (Zen)
- `Mod + Space`: Launcher (Noctalia)
- `Mod + W`: Close window
- `Mod + H/J/K/L`: Navigation (Vim-style)
- `Mod + Arrow Keys`: Navigation (Standard)
- `Mod + V`: Toggle floating
- `Mod + Escape`: Session menu (Noctalia)
