# Desktop Home Modules

User-specific desktop environment configuration managed via Home Manager.

## Configuration Profiles

Desktop modules are divided into a lightweight baseline and optional resource-heavy suites:

| Option | Description | Included Modules |
| :--- | :--- | :--- |
| `my.home.desktop.enable` | Lightweight baseline core | `bitwarden`, `browsers`, `communication`, `locales`, `niri`, `noctalia`, `theme`, `thunar`, `xdg`, `gpg-signing`, `dev-tools` (core) |
| `my.home.desktop.full.enable` | Full desktop experience | Adds `gaming`, `creative`, `media`, `office`, and heavy dev/AI tooling |

## Modules

| Module / Directory | Description |
| :--- | :--- |
| `bitwarden.nix` | Bitwarden desktop client with persistent autostart configuration. |
| `browsers/` | Declarative browser configs (Chromium, Zen Browser, userscript wrappers). |
| `communication.nix` | Messaging applications (Discord, Slack, Element). |
| `creative.nix` | Creative production tools (GIMP, Inkscape, Blender, OBS Studio). |
| [`dev-tools/`](dev-tools/README.md) | Development environments (Neovim, Ghostty, Git, Nix, AI agents). |
| `gaming.nix` | Gaming clients and NVIDIA PRIME offload wrappers. |
| `gpg-signing.nix` | GnuPG agent setup and SOPS-managed commit signing key import. |
| `locales.nix` | Locale and Fcitx5 / Mozc Japanese input method settings. |
| `media.nix` | Audio/video playback utilities and MPV player styling. |
| `niri/` | Niri scrollable-tiling Wayland compositor configuration (`config.kdl.nix`). |
| `noctalia/` | Noctalia Wayland desktop shell (bar, app launcher, notifications, wallpaper). |
| `office.nix` | Office suite (LibreOffice, PDF viewers). |
| `theme.nix` | GTK, Qt, and cursor theming derived from [`lib/palette.nix`](../../lib/palette.nix). |
| `thunar.nix` | Thunar file manager user preferences. |
| `xdg.nix` | XDG base directories and default MIME application associations. |
| `default.nix` | Desktop module aggregator and profile definitions. |

> [!NOTE]
> Zen Browser loads unsigned userscript extensions (`xpinstall.signatures.required = false`). After rebuilding the Nix configuration, restart Zen Browser to rescan the extension directory.

## References

- Palette definitions: [`lib/palette.nix`](../../lib/palette.nix)
- System desktop services: [`nixos/services/desktop/`](../../nixos/services/desktop/README.md)
- Development tools: [`home/desktop/dev-tools/`](dev-tools/README.md)
