# Desktop Profile

A role-based preset that bridges system-level services and user-level home configurations for a complete desktop experience.

## Features

- **Integrated Environment**: Combines Niri, PipeWire, NetworkManager, gaming, and common GUI apps.
- **Aggregate Flags**: `my.services.desktop.enable` and `my.home.desktop.enable` enable the whole desktop stack; individual sub-flags default to `true` and can be disabled per host.
- **Declarative User Sync**: Automatically configures the primary user's environment (Home Manager) when the profile is enabled.
- **Container Backing**: `my.virtualisation.distrobox.enable` (rootless podman) is enabled to support the Unity-via-Distrobox workflow.