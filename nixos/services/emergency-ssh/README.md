# Emergency SSH Access (`nixos/services/emergency-ssh/`)

Out-of-band SSH access service backed by Cloudflare Tunnel and Cloudflare Access SSH CA for remote disaster recovery when the Nebula mesh network is unreachable.

## Architecture & Authentication

The module runs an outbound Cloudflare Tunnel daemon connecting to Cloudflare Edge. Inbound access bypasses WAN firewall restrictions and mesh dependencies using a multi-layer defense model:

1. **Cloudflare Zero Trust (Access)**: Validates admin identity at the edge via OTP or IdP before forwarding traffic.
2. **Cloudflare SSH CA**: Issues short-lived certificates for browser-based Web terminals, verified by the host sshd against `/etc/ssh/cloudflare_ca.pub` and `/etc/ssh/auth_principals/%u`.
3. **User Public Key (ED25519)**: Enforces OS-level key authentication for PC CLI access (`cloudflared access ssh`).

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [default.nix](default.nix) | Configures `cloudflared-emergency-ssh.service`, registers Cloudflare CA keys, provisions user principals, and loads tunnel tokens via SOPS. | `my.services.emergencySsh.enable` |

## Operational Commands

```bash
# Check emergency tunnel service status
systemctl status cloudflared-emergency-ssh.service

# Inspect systemd credentials and token loading
systemctl show cloudflared-emergency-ssh.service -p LoadCredential

# Connect via CLI from an administrative workstation
cloudflared access ssh --hostname <hostname>-cf-ssh.t3u.uk
```

## References

- Emergency SSH runbook: [docs/operations/emergency-cf-ssh.md](../../../docs/operations/emergency-cf-ssh.md)
- Network recovery runbook: [docs/troubleshooting/network-recovery.md](../../../docs/troubleshooting/network-recovery.md)
- Secret management guide: [docs/operations/secret-management.md](../../../docs/operations/secret-management.md)
- Mesh network topology: [docs/architecture/network-topology.md](../../../docs/architecture/network-topology.md)
