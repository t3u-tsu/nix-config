# Base Modules

OS foundation shared by every host.

## Modules

- **`user.nix`**: Primary user (`my.user.*`) and root account setup. Password hashes are injected from SOPS (`hashedPasswordFile`); defines the `my.hostKey` SOPS key prefix.
- **`nix.nix`**: Nix daemon settings — flakes, trusted users, substituters with explicit priorities, weekly GC (`--delete-older-than 14d`), aarch64 emulation on x86_64 hosts.
- **`private-config.nix`**: Read-only deploy key for the private `nix-config-private` flake input and the `github-nix-config-private` ssh alias that uses it. The input is fetched while the flake is evaluated, so a host that has not applied this module yet cannot evaluate the flake at all — see [Bootstrap the private flake input](../../hosts/README.md#bootstrap-the-private-flake-input).
- **`time.nix`**: Timezone `Asia/Tokyo` and `chrony` NTP.
- **`default.nix`**: Imports the base modules.
