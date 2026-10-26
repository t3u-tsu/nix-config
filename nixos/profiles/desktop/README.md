# Desktop Profile (`nixos/profiles/desktop/`)

Configures system-level services and Home Manager user environments for graphical desktop systems.

## Profile Architecture

Desktop modules are divided into a lightweight baseline core and an opt-in full desktop stack:

| Tier | Option Flags | Included Components |
| :--- | :--- | :--- |
| **Baseline Core** (Default) | `my.services.desktop.enable = true;`<br>`my.home.desktop.enable = true;` | Niri Wayland compositor, Noctalia greeter & shell, PipeWire low-latency audio, Thunar file manager, CJK & coding fonts, Mesa GPU drivers, NetworkManager, Chromium/Zen baseline, GPG signing, LibreOffice, and core dev tools (Neovim, Ghostty). |
| **Full Stack** (Opt-in) | `my.services.desktop.full.enable = true;`<br>`my.home.desktop.full.enable = true;` | Steam & GameMode, containerized game engine toolchain (Distrobox / Podman), creative suite (GIMP, Blender, OBS Studio), media players, and local AI coding tooling (`agy`, `pi`, `dsh`). |

## Features & Integration

- Automatically wires `home/desktop` configurations into the primary user profile (`t3u`) when enabled.
- Enables `my.virtualisation.distrobox.enable` (rootless Podman) under `full.enable` to support containerized developer workflows.
- Exposes profile flags as defaults for all individual desktop module options, allowing granular per-host overrides.

## References

- System-level desktop services: [nixos/services/desktop/](../../services/desktop/README.md)
- User-level desktop configuration: [home/desktop/](../../../home/desktop/README.md)
- Shared palette definitions: [lib/palette.nix](../../../lib/palette.nix)
