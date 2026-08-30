# Desktop Profile

A role-based preset that bridges system-level services and user-level home configurations for a desktop experience.

## Features

- **Lightweight Core (default)**: `my.services.desktop.enable` and `my.home.desktop.enable` enable the base desktop stack — Niri, greetd, PipeWire, Thunar, fonts, graphics, NetworkManager, browsers, communication, theming, XDG, locales, GPG signing, and lightweight dev tools.
- **Full Stack (opt-in)**: `my.desktop.full.enable = true` (per host) opts into the heavier stack — gaming (Steam/GameMode/aagl + Chaotic-Nyx overlay), Unity/Distrobox (rootless podman), creative, media, office, and AI/hardware dev tools. Intended for machines that can afford the extra disk, build and eval time.
- **Aggregate Flags**: Most sub-flags default to `true` for the core and follow the `full` flag for the heavy categories; individual sub-flags can be overridden per host.
- **Declarative User Sync**: Automatically configures the primary user's environment (Home Manager) when the profile is enabled.
- **Container Backing**: `my.virtualisation.distrobox.enable` (rootless podman) is enabled with the full stack to support the Unity-via-Distrobox workflow.