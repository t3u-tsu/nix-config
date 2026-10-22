# Desktop Profile (`nixos/profiles/desktop/`)

Configures system-level services and Home Manager user environments for graphical desktop workstations.

## Profile Architecture

Desktop modules are divided into a lightweight baseline core and an opt-in full workstation stack:

| Tier | Option Flags | Included Components |
| :--- | :--- | :--- |
| **Baseline Core** (Default) | `my.services.desktop.enable = true;`<br>`my.home.desktop.enable = true;` | Niri Wayland compositor, Noctalia greeter & shell, PipeWire low-latency audio, Thunar file manager, CJK & coding fonts, Mesa GPU drivers, NetworkManager, Chromium/Zen baseline, GPG signing, and core dev tools (Neovim, Ghostty). |
| **Full Stack** (Opt-in) | `my.services.desktop.full.enable = true;`<br>`my.home.desktop.full.enable = true;` | Steam & GameMode, containerized game engine toolchain (Distrobox / Podman), creative suite (GIMP, Inkscape, Blender, OBS Studio), media players, LibreOffice, and local AI coding tooling (`agy`, `pi`, `dsh`). |

## Features & Integration

- **Home Manager Synchronization:** Wires `home/desktop` configurations into the primary user profile (`t3u`) automatically when enabled.
- **Container Runtime Support:** Automatically enables `my.virtualisation.distrobox.enable` (rootless Podman) under `full.enable` to back containerized developer workflows.
- **Fine-Grained Overrides:** All individual desktop module options default to the profile flags but remain independently overridable in per-host configurations.

## References

- System-level desktop services: [`nixos/services/desktop/`](../../services/desktop/README.md)
- User-level desktop configuration: [`home/desktop/`](../../../home/desktop/README.md)
- Shared palette definitions: [`lib/palette.nix`](../../../lib/palette.nix)
