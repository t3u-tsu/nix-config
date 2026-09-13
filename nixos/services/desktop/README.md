# Desktop Services (System Level)

This directory manages system-wide services and hardware integration for the desktop environment.

## Services

- **`niri.nix`**: Compositor setup and XDG Desktop Portals.
- **`greetd.nix`**: Login management and the graphical greeter.
- **`pipewire.nix`**: Audio stack and low-latency processing infrastructure.
- **`bluetooth.nix`**: Bluetooth stack, powered on at boot, with opt-in experimental features (LE Audio).
- **`fonts.nix`**: System-wide font configuration.
- **`thunar.nix`**: File manager with its gvfs/tumbler/xfconf system services.
- **`gaming.nix`**: Gaming performance tooling and launcher integration.
- **`unity.nix`**: Game-engine toolchain run in a container (system side: rootless podman).
- **`graphics.nix`**: Redistributable firmware and 32-bit GPU support.
- **`networkmanager.nix`**: Desktop network management.
- **`chromium.nix`**: Root-owned browser managed policies (`/etc/chromium/policies/managed`).
- **`default.nix`**: Master index for importing all desktop-related services; defines the aggregate `my.services.desktop.enable` flag (lightweight core) and `my.services.desktop.full.enable` for the gaming stack.