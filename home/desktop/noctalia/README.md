# Noctalia Desktop Shell (`home/desktop/noctalia/`)

Configuration for the Noctalia Wayland desktop shell, providing status bar capsules, an application launcher, a notification daemon, wallpaper transitions, and theme synchronization across desktop applications.

## Architecture & System Integration

### Shell Components

- **Status Bar**: Top bar with capsule groups for workspaces, system monitoring, privacy indicators, clock, notifications, clipboard history, networking, Bluetooth, volume, brightness, and power management.
- **Launcher & Control Center**: Fast keyboard-navigated app launcher and quick toggles for wireless interfaces, caffeine mode, and power profiles.
- **Theme Synchronization**: Uses Noctalia theme templates to render the Vesper palette into GTK3, GTK4, Qt (via `qt6ct`), Ghostty, Discord, and LazyGit configurations.
- **Wallpaper Engine**: Manages background transitions (crop or fit) and automated rotation from user wallpaper presets.

### IPC & D-Bus Communication

- **Shell IPC (`noctalia msg`)**: Dispatched by compositor hotkeys in Niri to perform actions such as volume control, brightness adjustments, and power cycle prompts.
- **Power Profile Integration**: Connects to the system `net.hadess.PowerProfiles` D-Bus interface provided by `tlp-pd` on supported laptops.
- **Fingerprint Verification**: The lock screen interfaces directly with `net.reactivated.Fprint` over D-Bus to authenticate users upon resume without requiring manual PAM prompts.

### Greeter Integration

The user-level Noctalia shell works in tandem with the system-level greeter:
- Configured via [nixos/services/desktop/greetd.nix](../../../nixos/services/desktop/greetd.nix) using `noctalia-greeter`.
- Reuses the shared Vesper palette and system wallpaper copied to `/var/lib/noctalia-greeter/wallpaper.jpg` during system activation.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [default.nix](default.nix) | Declares Noctalia options, bar widgets, theme templates, wallpaper presets, and Heroic theme directory hooks. | `my.home.desktop.noctalia.enable`, `wallpaperPreset` (`"minimal"`, `"PTITSA"`, `"ka256"`, `"suzushiro"`) |

## References

- Niri compositor configuration: [home/desktop/niri/](../niri/README.md)
- System display manager and greeter: [nixos/services/desktop/greetd.nix](../../../nixos/services/desktop/greetd.nix)
- Desktop profile specifications: [nixos/profiles/desktop/](../../../nixos/profiles/desktop/README.md)
- Palette definitions: [lib/palette.nix](../../../lib/palette.nix)
- ThinkPad X1C7 hardware guide: [docs/hardware/thinkpad-x1c7.md](../../../docs/hardware/thinkpad-x1c7.md)
- Fingerprint triage notes: [docs/research/fprintd-triage-notes.md](../../../docs/research/fprintd-triage-notes.md)
