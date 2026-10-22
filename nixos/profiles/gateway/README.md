# Gateway Profile (`nixos/profiles/gateway/`)

Host profile configuring edge routing, discovery lighthouse, and public-facing proxy services for the `torii-chan` gateway role.

## Profile Architecture

The gateway profile deploys the network boundary infrastructure shared between the physical SBC (`torii-chan`) and the automated failover cloud VPS (`torii-chan-vps`). It acts as the central pivot for overlay routing, dynamic DNS updates, and WAN ingress traffic forwarding.

### Profile Scope

| Domain | Role & Responsibilities |
| :--- | :--- |
| Nebula Mesh Backbone | Hosts the central discovery lighthouse and relay node (`10.0.0.1:4242`) for the private mesh network. |
| Dynamic DNS | Updates public A records for `torii-chan.t3u.uk`, `mc.t3u.uk`, and `*.mc.t3u.uk` via Cloudflare API. |
| Port Forwarding & Proxy | Forwards public Minecraft traffic (`tcp/25565`) to internal server `shosoin-tan` (`10.0.0.4:25565`) across Nebula. |
| WAN Boundary Hardening | Restricts WAN ports strictly to UDP 4242 and TCP 25565 while confining SSH to the `nebula0` interface. |

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [default.nix](default.nix) | Enables gateway services and network routing modules. | Sets `config.my.services.gateway.enable = true;` |

## References

- Gateway services implementation: [nixos/services/gateway/](../../services/gateway/README.md)
- Orange Pi Zero 3 hardware guide: [docs/hardware/orange-pi-zero3.md](../../../docs/hardware/orange-pi-zero3.md)
- ConoHa VPS failover & failback runbook: [docs/operations/vps-failover.md](../../../docs/operations/vps-failover.md)
- Network topology: [docs/architecture/network-topology.md](../../../docs/architecture/network-topology.md)
- Host configuration: [hosts/torii-chan/](../../../hosts/torii-chan/README.md)
