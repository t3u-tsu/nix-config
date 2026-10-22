# Tower Server Profile (`nixos/profiles/tower-server/`)

Baseline configuration shared across all headless tower servers (`shosoin-tan`, `kagutsuchi-sama`, `sando-kun`).

## Profile Features

- Deploys default stock kernel packages (`pkgs.linuxPackages`) to ensure predictable driver stability across legacy Nehalem and Ivy Bridge platforms.
- Restricts SSH access to the Nebula overlay mesh network (`allowedTCPPorts = mkForce []`).
- Hardens OpenSSH by enforcing key-based authentication (`PasswordAuthentication = false`) and disabling root logins (`PermitRootLogin = "no"`).
- Preconfigures hardware diagnostics via `pc-tools` (nvme-cli, smartmontools) and assigns the primary user to the `wheel`, `video`, and `render` groups.

## Modules

| File | Purpose |
| :--- | :--- |
| [`boot.nix`](boot.nix) | Stock default kernel deployment (`pkgs.linuxPackages`). |
| [`security.nix`](security.nix) | Inbound firewall isolation restricting SSH to `nebula0`. |
| [`ssh.nix`](ssh.nix) | Key-only OpenSSH server hardening. |
| [`default.nix`](default.nix) | Aggregates server profile modules and hardware monitoring tools. |

## References

- Storage and Legacy BIOS guide: [`docs/hardware/storage-zfs.md`](../../../docs/hardware/storage-zfs.md)
- Network mesh topology: [`docs/architecture/network-topology.md`](../../../docs/architecture/network-topology.md)
