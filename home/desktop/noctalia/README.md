# Noctalia Desktop Shell (`home/desktop/noctalia/`)

Configuration for the Noctalia Wayland desktop shell, providing status bar capsules, an application launcher, a notification daemon, wallpaper transitions, and theme synchronization across desktop applications.

## Architecture & System Integration

### Shell Components

| Component | Functionality |
| :--- | :--- |
| Status Bar | Top bar capsules for workspaces, system monitoring, privacy indicators, clock, notifications, clipboard, networking, Bluetooth, and power. |
| Launcher & Control Center | Keyboard-navigated app launcher and quick toggles for wireless interfaces, caffeine mode, and power profiles. |
| Theme Synchronization | Renders the Vesper palette via Noctalia theme templates into GTK3, GTK4, Qt (via `qt6ct`), Ghostty, Discord, and lazygit. |
| Wallpaper Engine | Manages background transitions and automated rotation across user wallpaper presets. |

### IPC & D-Bus Communication

| Interface | Integration Details |
| :--- | :--- |
| Shell IPC (`noctalia msg`) | Dispatched by Niri hotkeys for volume control, brightness adjustments, and power cycle prompts. |
| Power Profiles | Connects to `net.hadess.PowerProfiles` D-Bus interface provided by `tlp-pd`. |
| Fingerprint Verification | Lock screen interfaces directly with `net.reactivated.Fprint` over D-Bus upon session resume. |

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
