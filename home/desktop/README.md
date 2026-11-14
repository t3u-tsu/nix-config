# Desktop Modules (`home/desktop/`)

User-specific desktop environment configuration managed with Home Manager.

## Configuration Profiles

Desktop modules provide a baseline configuration and an optional full desktop suite:

| Option | Description | Included Modules |
| :--- | :--- | :--- |
| `my.home.desktop.enable` | Baseline desktop core | `bitwarden`, `browsers`, `communication`, `dev-tools` (core), `documents`, `gpg-signing`, `locales`, `niri`, `noctalia`, `theme`, `thunar`, `xdg` |
| `my.home.desktop.full.enable` | Full desktop suite | Adds `gaming`, `creative`, `media`, and heavy dev/AI tooling |

## Modules

| File | Description | Options |
| :--- | :--- | :--- |
| [default.nix](default.nix) | Desktop module aggregator and profile definitions. | `my.home.desktop.enable`, `my.home.desktop.full.enable` |
| [bitwarden.nix](bitwarden.nix) | Bitwarden desktop client, CLI (`bitwarden-cli`), and persistent autostart configuration. | `my.home.desktop.bitwarden.enable` |
| [browsers/](browsers/README.md) | Declarative browser configs (Chromium, Zen Browser, userscript wrappers). | `my.home.desktop.browsers.*` |
| [communication.nix](communication.nix) | Messaging applications (Discord (optional), Vesktop, Thunderbird). | `my.home.desktop.communication.enable` |
| [creative.nix](creative.nix) | Creative production tools (GIMP, Blender, OBS Studio). | `my.home.desktop.creative.enable` |
| [dev-tools/](dev-tools/README.md) | Development environments (Neovim, Ghostty, Git, Nix, AI agents). | `my.home.desktop.dev-tools.*` |
| [documents.nix](documents.nix) | Document viewers and office tools (LibreOffice, Sioyek, MarkText). | `my.home.desktop.documents.enable` |
| [gaming.nix](gaming.nix) | Gaming clients and NVIDIA PRIME offload wrappers. | `my.home.desktop.gaming.enable` |
| [gpg-signing.nix](gpg-signing.nix) | GnuPG agent setup and agenix-managed commit signing key import. | `my.home.desktop.gpg-signing.enable` |
| [locales.nix](locales.nix) | Locale and Fcitx5 / Mozc Japanese input method settings. | `my.home.desktop.locales.enable` |
| [media.nix](media.nix) | Media playback (Spotify via Spicetify, VLC). | `my.home.desktop.media.enable` |
| [niri/](niri/README.md) | Niri scrollable-tiling Wayland compositor configuration (`config.kdl`). | `my.home.desktop.niri.enable` |
| [noctalia/](noctalia/README.md) | Noctalia Wayland desktop shell (bar, app launcher, notifications, wallpaper). | `my.home.desktop.noctalia.enable` |
| [theme.nix](theme.nix) | GTK, Qt, and cursor theming derived from [lib/palette.nix](../../lib/palette.nix). | `my.home.desktop.theme.enable` |
| [thunar.nix](thunar.nix) | Thunar file manager user preferences. | `my.home.desktop.thunar.enable` |
| [xdg.nix](xdg.nix) | XDG base directories and default MIME application associations. | `my.home.desktop.xdg.enable` |

> [!NOTE]
> Zen Browser loads unsigned userscript extensions (`xpinstall.signatures.required = false`). After rebuilding the Nix configuration, restart Zen Browser to rescan the extension directory.

## References

- Palette definitions: [lib/palette.nix](../../lib/palette.nix)
- System desktop services: [nixos/services/desktop/](../../nixos/services/desktop/README.md)
- Development tools: [home/desktop/dev-tools/](dev-tools/README.md)
