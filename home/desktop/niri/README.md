# Niri Compositor (`home/desktop/niri/`)

User-level configuration for the [Niri](https://github.com/YaLTeR/niri) scrollable-tiling Wayland compositor, managing layout behavior, input mapping, hardware hotkeys, and color palette templating.

## Architecture & Configuration Flow

Niri is configured via a structured KDL configuration file evaluated through a template replacement pipeline:

1. **Palette & Theme Templating**: `default.nix` injects color definitions from [lib/palette.nix](../../../lib/palette.nix) (`@background@`, `@primary@`, `@error@`, `@low@`, `@cast-inactive@`) along with cursor theme names and sizes into `config.kdl` placeholders.
2. **Build-Time Validation**: The generated KDL is validated at package build time using `niri validate` via `niri-flake`.
3. **Desktop Shell Integration**: Hotkeys dispatch commands directly to the Noctalia desktop shell IPC interface (`noctalia msg volume-up`, `noctalia msg brightness-down`, `noctalia msg power-cycle`).
4. **XWayland Isolation**: Legacy X11 applications run through `xwayland-satellite` on demand rather than an integrated X11 server root.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [default.nix](default.nix) | Home Manager module that applies template substitutions to `config.kdl` and installs essential Wayland tools. | `my.home.desktop.niri.enable` |
| [config.kdl](config.kdl) | Compositor configuration covering window layout, animations, gestures, hotkeys, and window rules. | Contains `@name@` placeholders replaced at build time |

## References

- Noctalia desktop shell integration: [home/desktop/noctalia/](../noctalia/README.md)
- Palette definitions: [lib/palette.nix](../../../lib/palette.nix)
- Desktop profile: [nixos/profiles/desktop/](../../../nixos/profiles/desktop/README.md)
- System display manager: [nixos/services/desktop/greetd.nix](../../../nixos/services/desktop/greetd.nix)
