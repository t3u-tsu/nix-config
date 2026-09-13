# Desktop Home Modules

User-specific desktop environment configuration managed via Home Manager.

The lightweight core is `my.home.desktop.enable`; heavy extras are opted in with
`my.home.desktop.full.enable` (see `default.nix`).

## Modules

- **`browsers.nix`**: Browsers with declarative settings; system-level browser policy lives in `nixos/services/desktop/chromium.nix`.
- **`palette.nix`**: Shared color palette used by the desktop modules — a data file, not a module, so `default.nix` does not import it.
- **`theme.nix`**: GTK, Qt and cursor theme configuration.
- **`locales.nix`**: Locale and input method settings.
- **`xdg.nix`**: XDG user directories and default application MIME associations.
- **`gpg-signing.nix`**: GnuPG agent setup and SOPS-managed signing key import.
- **`communication.nix`**: Messaging applications.
- **`gaming.nix`**: User-level gaming tools and NVIDIA PRIME offload launchers.
- **`media.nix`**: Media playback and player theming.
- **`office.nix`**: Office suite.
- **`creative.nix`**: Creative apps — image editing, recording and 3D modelling.
- **`thunar.nix`**: File manager user settings; system services live in `nixos/services/desktop/thunar.nix`.
- **`niri/`**: Wayland compositor settings — `config.kdl.nix` renders the KDL config from the palette.
- **`noctalia/`**: Wayland shell — bar, launcher, notifications, wallpaper and theme templates.
- [`dev-tools/`](dev-tools/README.md): Development environment — editors, terminals, Nix and AI tooling.
- **`default.nix`**: Imports all desktop home modules and defines the `enable` / `full.enable` split.
