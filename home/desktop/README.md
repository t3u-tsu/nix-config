# Desktop Home Modules

User-specific desktop environment configuration managed via Home Manager.

The lightweight core is `my.home.desktop.enable`; heavy extras are opted in with
`my.home.desktop.full.enable` (see `default.nix`).

## Modules

- **`browsers/`**: Browsers with declarative settings (`chromium.nix`, `zen.nix`, and `userscripts.nix`, which wraps upstream userscripts as extensions); system-level browser policy lives in `nixos/services/desktop/chromium.nix`.

  The userscript extensions are unsigned, so `zen.nix` sets `xpinstall.signatures.required = false`. Zen is a self-compiled fork and honours the pref; without it Firefox discards unsigned xpis **without any error or log entry**, which makes the failure hard to diagnose. Zen has to be restarted after a rebuild for the new extension directory to be rescanned.

  The pins and essentials are personal, so they live in the private `nix-config-private` repository (`zen/pins.nix`) and are imported by `zen.nix`. The three space ids stay here because `spaces` and `spaceRouting` use them too.

- **`theme.nix`**: Cursor, GTK and Qt setup. GTK and Qt colors come from Noctalia's built-in `gtk3` / `gtk4` / `qt` templates; the shared palette lives in [`lib/palette.nix`](../../lib/palette.nix).
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
- [`dev-tools/`](dev-tools/): Development environment — editors, terminals, Nix and AI tooling.
- **`default.nix`**: Imports all desktop home modules and defines the `enable` / `full.enable` split.
