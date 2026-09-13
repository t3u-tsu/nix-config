# Desktop Home Modules

User-specific desktop environment configuration managed via Home Manager.

The lightweight core is `my.home.desktop.enable`; heavy extras are opted in with
`my.home.desktop.full.enable` (see `default.nix`).

## Modules

- **`browsers.nix`**: Zen Browser (declarative settings, `userChrome`/`userContent`) and Chromium. System-level Chromium policy lives in `nixos/services/desktop/chromium.nix`.
- **`palette.nix`**: Vesper color palette shared by the desktop modules — a data file, not a module, so `default.nix` does not import it.
- **`theme.nix`**: GTK, Qt/qt6ct and cursor theme configuration.
- **`locales.nix`**: Locale and Fcitx5 input method settings.
- **`xdg.nix`**: XDG user directories and default application MIME associations.
- **`gpg-signing.nix`**: GnuPG agent setup and SOPS-managed signing key import.
- **`communication.nix`**: Messaging applications (Discord, Vesktop, Thunderbird).
- **`gaming.nix`**: User-level gaming tools and NVIDIA PRIME offload launchers.
- **`media.nix`**: VLC and Spicetify theming.
- **`office.nix`**: LibreOffice.
- **`creative.nix`**: GIMP, OBS Studio and Blender.
- **`thunar.nix`**: Thunar user settings; system services live in `nixos/services/desktop/thunar.nix`.
- **`niri/`**: Niri Wayland compositor settings — `config.kdl.nix` renders the KDL config from the palette.
- **`noctalia/`**: Noctalia Wayland shell (bar, launcher, notifications, wallpaper, theme templates).
- **`dev-tools/`**: Development tools (Neovim, Ghostty, Nix, AI tools, hardware, Unity).
- **`default.nix`**: Imports all desktop home modules and defines the `enable` / `full.enable` split.
