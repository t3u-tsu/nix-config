# Desktop Services (System Level)

This directory manages system-wide services and hardware integration for the desktop environment.

## Services

- **`niri.nix`**: System-level Niri compositor setup and XDG Desktop Portals.
- **`greetd.nix`**: Login management using `greetd` and the `tuigreet` TUI greeter.
- **`pipewire.nix`**: PipeWire-based audio and low-latency processing infrastructure.
- **`fonts.nix`**: System-wide font configuration (Noto, Nerd Fonts).
- **`thunar.nix`**: Thunar file manager with gvfs/tumbler/xfconf system services.
- **`gaming.nix`**: Steam, GameMode, and performance-related gaming tools.
- **`unity.nix`**: Unity Hub & Editor via Distrobox (system side: podman + rootless podman).
- **`graphics.nix`**: Redistributable firmware and 32-bit GPU support.
- **`networkmanager.nix`**: NetworkManager for desktop network management.
- **`default.nix`**: Master index for importing all desktop-related services; defines the aggregate `my.services.desktop.enable` flag (lightweight core) and `my.services.desktop.full.enable` for the gaming/Unity stack.