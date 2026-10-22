# Desktop Services (`nixos/services/desktop/`)

System-level background daemons, hardware integration, and policy managers for the graphical desktop environment.

## Modules Overview

| Module | Component | Description | Profile |
| :--- | :--- | :--- | :--- |
| [`niri.nix`](niri.nix) | Niri Compositor | Wayland compositor integration and XDG Desktop Portals. | Core (`desktop.enable`) |
| [`greetd.nix`](greetd.nix) | Login Greeter | Greetd login daemon running Noctalia greeter styled via [`lib/palette.nix`](../../../lib/palette.nix). | Core (`desktop.enable`) |
| [`pipewire.nix`](pipewire.nix) | Audio Stack | Low-latency audio processing via PipeWire, WirePlumber, and ALSA/Pulse emulation. | Core (`desktop.enable`) |
| [`bluetooth.nix`](bluetooth.nix) | Bluetooth | BlueZ daemon enabled at boot with experimental LE Audio support. | Core (`desktop.enable`) |
| [`fonts.nix`](fonts.nix) | Typography | Declarative font packages (Noto Sans CJK JP, JetBrains Mono, nerd fonts). | Core (`desktop.enable`) |
| [`thunar.nix`](thunar.nix) | File Manager | System services for Thunar (`gvfs` virtual filesystem, `tumbler` thumbnails). | Core (`desktop.enable`) |
| [`graphics.nix`](graphics.nix) | Graphics Drivers | Mesa OpenGL/Vulkan hardware acceleration and 32-bit runtime libraries. | Core (`desktop.enable`) |
| [`networkmanager.nix`](networkmanager.nix) | Networking | NetworkManager daemon and polkit permission delegation. | Core (`desktop.enable`) |
| [`chromium.nix`](chromium.nix) | Enterprise Policies | Declarative managed policies written to `/etc/chromium/policies/managed`. | Core (`desktop.enable`) |
| [`bitwarden.nix`](bitwarden.nix) | Bitwarden | System-level Bitwarden desktop and CLI packages. | Core (`desktop.enable`) |
| [`gaming.nix`](gaming.nix) | Gaming Platform | Steam hardware udev rules, GameMode daemon, and offload launchers. | Full (`full.enable`) |
| [`unity.nix`](unity.nix) | Game Engine | Rootless Podman container support backing the Unity development environment. | Full (`full.enable`) |
| [`default.nix`](default.nix) | Aggregator | Declares `my.services.desktop.enable` and `full.enable` aggregate options. | — |

## References

- Desktop profile overview: [`nixos/profiles/desktop/`](../../profiles/desktop/README.md)
- User desktop environment: [`home/desktop/`](../../../home/desktop/README.md)
- Vesper palette configuration: [`lib/palette.nix`](../../../lib/palette.nix)
