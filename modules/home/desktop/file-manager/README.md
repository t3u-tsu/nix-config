# File Manager Module (Thunar)

This module configures **Thunar** as the standard file manager for the Niri desktop environment.

## Design Philosophy / Reason for migrating from Nautilus

Previously, Nautilus was used, but its heavy reliance on GNOME made it less than optimal in terms of resources and customization within a lightweight Wayland compositor (Niri) environment.

In Phase 7, we fully migrated to **Thunar (Xfce)**, which is lighter and highly customizable.

## Feature Integration and Customization

To use Thunar comfortably in a standalone (non-Xfce) environment, it is combined with the following system services (these are enabled at the system level in files like `niri.nix`):

- **gvfs**: Trash support, and automatic mounting and display of external drives like USB sticks.
- **tumbler**: Generation and display of image and video thumbnails.
- **xfconf**: Persistence of settings independent of the desktop environment.

### Custom Settings
- **Privacy Protection**: The tracking and display of `Recent Files` history is explicitly disabled via `xfconf`.
- **Convenience**: The `thunar-archive-plugin` is added, allowing direct archive creation and extraction from the right-click menu.
