# Browser Environments (`home/desktop/browsers/`)

Web browser configuration and integration modules for graphical workstations, managing Zen Browser (Firefox-based), Chromium, userscript packaging, and desktop password manager IPC.

## Architecture & Integration

- **Zen Browser**: Configured declaratively via `inputs.zen-browser.homeModules.default` with hardened policies (telemetry disabled), extensions installed from AMO via IDs, workspace container routing, and custom CSS styled with the shared Vesper palette.
- **Bitwarden IPC Bridge**: Installs the native messaging manifest `com.8bit.bitwarden.json` directly into `~/.mozilla/native-messaging-hosts/` during Home Manager activation, allowing the Zen extension to communicate with `bitwarden-desktop`.
- **Standalone Userscript Packaging**: Uses `mkUserscriptXpi` to package upstream `.user.js` files into isolated WebExtension XPIs installed into `share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}`, eliminating the overhead and privileged APIs of third-party userscript manager extensions.
- **Chromium**: Maintained as a secondary browser for site compatibility and web development, configured with minimal startup flags.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [default.nix](default.nix) | Aggregator module declaring browser options and setting default enablement. | `my.home.desktop.browsers.enable`, `zen.enable`, `chromium.enable` |
| [zen.nix](zen.nix) | Zen Browser profile, policy hardening, AMO extensions, workspace routing, and Vesper palette styling. | Active when `zen.enable = true;` |
| [chromium.nix](chromium.nix) | Chromium configuration with clean startup arguments (`--no-first-run`, `--no-default-browser-check`). | Active when `chromium.enable = true;` |
| [bitwarden.nix](bitwarden.nix) | Firefox/Zen native messaging host manifest provisioning for desktop application integration. | `my.home.desktop.browsers.bitwarden.enable` (defaults to true with Zen) |
| [userscripts.nix](userscripts.nix) | Builds and installs standalone XPI extensions from raw `.user.js` sources without external managers. | `my.home.desktop.browsers.userscripts.enable` (defaults to true with Zen) |

## References

- Desktop profile specifications: [nixos/profiles/desktop/](../../../nixos/profiles/desktop/README.md)
- Color palette definition: [lib/palette.nix](../../../lib/palette.nix)
- Desktop theme integration: [home/desktop/theme.nix](../theme.nix)
- System-level Chromium enterprise policies: [nixos/services/desktop/chromium.nix](../../../nixos/services/desktop/chromium.nix)
