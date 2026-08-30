# Base Modules

OS foundation shared by every host.

## Modules

- **`user.nix`**: Primary user (`my.user.*`) and root account setup. Password hashes are injected from SOPS (`hashedPasswordFile`); defines the `my.hostKey` SOPS key prefix.
- **`nix.nix`**: Nix daemon settings — flakes, trusted users, Cachix substituters with explicit priorities, weekly GC (`--delete-older-than 14d`), aarch64 emulation on x86_64 hosts.
- **`time.nix`**: Timezone `Asia/Tokyo` and `chrony` NTP.
- **`default.nix`**: Imports the base modules.