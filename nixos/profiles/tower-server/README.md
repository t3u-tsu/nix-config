# Tower Server Profile

Common configuration for the tower servers (shosoin-tan / kagutsuchi-sama / sando-kun).

## Modules

- **`boot.nix`**: Stock kernel (`pkgs.linuxPackages`) for stability on older hardware.
- **`security.nix`**: SSH restricted to the Nebula mesh only — `allowedTCPPorts = mkForce []` (in-tunnel SSH is governed by each host's Nebula firewall).
- **`ssh.nix`**: OpenSSH with key-only auth (`PasswordAuthentication = false`, `PermitRootLogin = "no"`).
- **`default.nix`**: Imports the modules; adds wheel/video/render groups and PC tools.