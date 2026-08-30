# Desktop Home Modules

User-specific desktop environment configurations managed via Home Manager.

## Modules

- **`browsers.nix`**: Zen Browser configuration with declarative settings.
- **`theme.nix`**: GTK and cursor theme configurations.
- **`locales.nix`**: Desktop localization settings.
- **`xdg.nix`**: XDG user directories and default application MIME associations.
- **`gpg-signing.nix`**: GnuPG agent setup and configuration.
- **`communication.nix`**: Messaging applications (e.g. Discord/Vesktop).
- **`gaming.nix`**: User-level gaming options and tools.
- **`media.nix`**: Media players and utility apps.
- **`creative.nix`**: Design and creative tools.
- **`thunar.nix`**: Thunar file manager settings (system services live in `nixos/services/desktop/thunar.nix`).
- **`niri/`**: Niri Wayland compositor settings.
- **`dev-tools/`**: Development tools configuration (Neovim, Ghostty).
- **`default.nix`**: Imports all desktop home modules.
