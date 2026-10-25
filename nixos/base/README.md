# Base Modules (`nixos/base/`)

Core OS baseline configuration applied to all fleet machines.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [user.nix](user.nix) | Primary user (`my.user.*`) and root accounts with hashed passwords injected via agenix. | Defines the primary user and authorized keys. |
| [nix.nix](nix.nix) | Nix daemon settings: flakes, trusted users, binary substituters with priorities, weekly GC (`--delete-older-than 14d`), and `aarch64` binfmt emulation on `x86_64`. | Enabled by default. |
| [private-config.nix](private-config.nix) | Deploy key injection for the private `nix-config-private` flake input and SSH alias `github-nix-config-private`. | Requires bootstrap during clean installs. |
| [time.nix](time.nix) | Timezone (`Asia/Tokyo`) and Chrony NTP synchronization. | Enabled by default. |
| [i18n.nix](i18n.nix) | System locale (`ja_JP.UTF-8`, `en_US.UTF-8`) and console keymap (`us`). | `my.base.i18n.*` (`enable` defaults to `true`). |
| [default.nix](default.nix) | Aggregates base modules. | — |

## References

- Private Flake bootstrap: [docs/operations/adding-a-host.md#step-5-プライベート-flake-入力のブートストラップ](../../docs/operations/adding-a-host.md#step-5-プライベート-flake-入力のブートストラップ)
- Garbage collection and updates: [docs/operations/maintenance.md](../../docs/operations/maintenance.md)
