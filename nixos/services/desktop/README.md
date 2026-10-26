# Desktop Services (`nixos/services/desktop/`)

System-level background daemons, hardware integration, and policy managers for the graphical desktop environment.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [niri.nix](niri.nix) | Niri Wayland compositor integration and XDG Desktop Portals. | Core (`desktop.enable`) |
| [greetd.nix](greetd.nix) | Greetd login daemon running the Noctalia greeter styled via [lib/palette.nix](../../../lib/palette.nix). | Core (`desktop.enable`) |
| [pipewire.nix](pipewire.nix) | Low-latency audio stack via PipeWire, WirePlumber, and ALSA/Pulse emulation. | Core (`desktop.enable`) |
| [bluetooth.nix](bluetooth.nix) | BlueZ daemon enabled at boot with experimental LE Audio support. | Core (`desktop.enable`) |
| [fonts.nix](fonts.nix) | Declarative font packages (Noto Sans CJK JP, JetBrains Mono, nerd fonts). | Core (`desktop.enable`) |
| [thunar.nix](thunar.nix) | Thunar file manager services (`gvfs` virtual filesystem, `tumbler` thumbnails). | Core (`desktop.enable`) |
| [graphics.nix](graphics.nix) | Mesa OpenGL/Vulkan hardware acceleration and 32-bit runtime libraries. | Core (`desktop.enable`) |
| [networkmanager.nix](networkmanager.nix) | NetworkManager daemon and polkit permission delegation. | Core (`desktop.enable`) |
| [chromium.nix](chromium.nix) | Declarative managed policies written to `/etc/chromium/policies/managed`. | Core (`desktop.enable`) |
| [gaming.nix](gaming.nix) | Steam hardware udev rules, GameMode daemon, and offload launchers. | Full (`full.enable`) |
| [unity.nix](unity.nix) | Rootless Podman container support backing the Unity development environment. | Full (`full.enable`) |
| [default.nix](default.nix) | Aggregator declaring `my.services.desktop.enable` and `full.enable` aggregate options. | — |

## References

- Desktop profile overview: [nixos/profiles/desktop/](../../profiles/desktop/README.md)
- User desktop environment: [home/desktop/](../../../home/desktop/README.md)
- Vesper palette configuration: [lib/palette.nix](../../../lib/palette.nix)
