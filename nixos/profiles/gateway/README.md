# Gateway Profile

The **torii-chan** role: a Nebula mesh gateway (Lighthouse + Relay) with DDNS and Minecraft port-forwarding. Enabled via `my.services.gateway.enable`; shared by the physical SBC and the failover VPS.

## Modules

- **`firewall.nix`**: WAN firewall — only TCP 25565 exposed by default (`restrictAccess`), NAT/MASQUERADE for the Minecraft backend.
- **`hardening.nix`**: Kernel hardening sysctls (kptr_restrict, dmesg_restrict, BPF, rp_filter, redirects).
- **`nebula.nix`**: Nebula node wiring — `10.0.0.1`, Lighthouse + Relay, inbound 22 (mgmt) + 25565 (app).
- **`ssh.nix`**: OpenSSH with key-only auth, restricted to the Nebula mesh.
- **`ddns.nix`**: Cloudflare DDNS via `ddclient` for `torii-chan.t3u.uk`, `mc.t3u.uk`, `*.mc.t3u.uk`.

Platform-specific wiring (SBC vs VPS) lives in `hosts/torii-chan/` — see `hosts/torii-chan/README.md`.