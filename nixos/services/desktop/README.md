# Desktop Services (System Level)

This directory manages system-wide services and hardware integration for the desktop environment.

## Services

- **`niri.nix`**: System-level Niri compositor setup and XDG Desktop Portals.
- **`greetd.nix`**: Login management using `greetd` and the `tuigreet` TUI greeter.
- **`pipewire.nix`**: PipeWire-based audio and low-latency processing infrastructure.
- **`fonts.nix`**: System-wide font configuration (Noto, Nerd Fonts).
- **`thunar.nix`**: Thunar file manager with gvfs/tumbler/xfconf system services.
- **`gaming.nix`**: Steam, GameMode, and performance-related gaming tools.
- **`default.nix`**: Master index for importing all desktop-related services.
