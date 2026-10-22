# Tower Server Profile (`nixos/profiles/tower-server/`)

Baseline configuration shared across all headless tower servers (`shosoin-tan`, `kagutsuchi-sama`, `sando-kun`).

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [boot.nix](boot.nix) | Stock kernel packages (`pkgs.linuxPackages`). | Keeps legacy Nehalem and Ivy Bridge drivers stable |
| [security.nix](security.nix) | Firewall policy clearing public TCP ports so SSH is reachable only over `nebula0`. | `allowedTCPPorts = mkForce []` |
| [ssh.nix](ssh.nix) | OpenSSH server hardening. | `PasswordAuthentication = false`, `PermitRootLogin = "no"` |
| [default.nix](default.nix) | Profile aggregator with hardware diagnostics. | Enables `pc-tools`; adds the primary user to `wheel`, `video`, `render` |

## References

- Storage and Legacy BIOS guide: [docs/hardware/storage-zfs.md](../../../docs/hardware/storage-zfs.md)
- Network mesh topology: [docs/architecture/network-topology.md](../../../docs/architecture/network-topology.md)
