# Desktop Home Modules

User-specific desktop environment configuration managed with Home Manager.

## Configuration Profiles

Desktop modules provide a baseline configuration and an optional full workstation suite:

| Option | Description | Included Modules |
| :--- | :--- | :--- |
| `my.home.desktop.enable` | Baseline desktop core | `bitwarden`, `browsers`, `communication`, `dev-tools` (core), `gpg-signing`, `locales`, `niri`, `noctalia`, `office`, `theme`, `thunar`, `xdg` |
| `my.home.desktop.full.enable` | Full workstation suite | Adds `gaming`, `creative`, `media`, and heavy dev/AI tooling |

## Modules

| Module / Directory | Description |
| :--- | :--- |
| [bitwarden.nix](bitwarden.nix) | Bitwarden desktop client with persistent autostart configuration. |
| [browsers/](browsers/README.md) | Declarative browser configs (Chromium, Zen Browser, userscript wrappers). |
| [communication.nix](communication.nix) | Messaging applications (Discord (optional), Vesktop, Thunderbird). |
| [creative.nix](creative.nix) | Creative production tools (GIMP, Blender, OBS Studio). |
| [dev-tools/](dev-tools/README.md) | Development environments (Neovim, Ghostty, Git, Nix, AI agents). |
| [gaming.nix](gaming.nix) | Gaming clients and NVIDIA PRIME offload wrappers. |
| [gpg-signing.nix](gpg-signing.nix) | GnuPG agent setup and SOPS-managed commit signing key import. |
| [locales.nix](locales.nix) | Locale and Fcitx5 / Mozc Japanese input method settings. |
| [media.nix](media.nix) | Media playback (Spotify via Spicetify, VLC). |
| [niri/](niri/README.md) | Niri scrollable-tiling Wayland compositor configuration (`config.kdl`). |
| [noctalia/](noctalia/README.md) | Noctalia Wayland desktop shell (bar, app launcher, notifications, wallpaper). |
| [office.nix](office.nix) | Office suite (LibreOffice). |
| [theme.nix](theme.nix) | GTK, Qt, and cursor theming derived from [lib/palette.nix](../../lib/palette.nix). |
| [thunar.nix](thunar.nix) | Thunar file manager user preferences. |
| [xdg.nix](xdg.nix) | XDG base directories and default MIME application associations. |
| [default.nix](default.nix) | Desktop module aggregator and profile definitions. |

> [!NOTE]
> Zen Browser loads unsigned userscript extensions (`xpinstall.signatures.required = false`). After rebuilding the Nix configuration, restart Zen Browser to rescan the extension directory.

## References

- Palette definitions: [lib/palette.nix](../../lib/palette.nix)
- System desktop services: [nixos/services/desktop/](../../nixos/services/desktop/README.md)
- Development tools: [home/desktop/dev-tools/](dev-tools/README.md)
