# System Development Hardware (`nixos/dev-tools/`)

System-level udev rules and hardware privileges for developer tooling.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [wch-linke.nix](wch-linke.nix) | udev rules granting unprivileged user access to WCH-LinkE RISC-V/ARM debug probes. | Enabled with `my.dev-tools.enable` |
| [ventoy.nix](ventoy.nix) | Explicit security override (`permittedInsecurePackages`) for Ventoy USB installer packages. | Enabled with `my.dev-tools.enable` |
| [default.nix](default.nix) | Category flag definition (`my.dev-tools.enable`) and aggregator. | — |

## References

- User-level dev tools: [home/desktop/dev-tools/](../../home/desktop/dev-tools/README.md)
