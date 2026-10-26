# ConoHa VPS Infrastructure (`terraform/`)

Infrastructure as Code managed via [OpenTofu](https://opentofu.org/) (`tofu`) for the failover Lighthouse and relay VPS (`torii-chan-vps`).

## Resources Overview

| Resource | Terraform Name | Description |
| :--- | :--- | :--- |
| SSH Key Pair | `conohavps_keypair.t3u` | Operator SSH public key. |
| Security Group | `conohavps_securitygroup.torii_chan` | Allows TCP 22 (SSH), UDP 4242 (Nebula), ICMP, and all IPv4 outbound. |
| Storage Volume | `conohavps_volume.boot` | 30 GB SSD boot volume (`c3j1-ds02-boot`). |
| Compute Instance | `conohavps_instance.torii_chan` | 512 MB VPS plan (`g2l-t-c1m512`) in region `c3j1`. |

## Environment Variables & Credentials

Export credentials to the environment before running `tofu`:

```bash
# ConoHa API credentials (set directly or injected from Bitwarden)
export CONOHAVPS_USER_ID="<openstack-user-id>"
export CONOHAVPS_PASSWORD="<openstack-password>"
export CONOHAVPS_TENANT_ID="<openstack-tenant-id>"

# Required Terraform inputs
export TF_VAR_admin_password="<secure-root-password>"
export TF_VAR_ssh_public_key="ssh-ed25519 AAAA... t3u@BrokenPC"
```

## CLI Operations

```bash
tofu init      # Install provider plugins
tofu validate  # Validate syntax
tofu plan      # Inspect planned infrastructure changes
tofu apply     # Provision VPS (starts billing; requires user approval)
tofu output -json torii_chan_addresses  # Retrieve assigned public IP
tofu destroy   # Tear down VPS and stop billing (requires user approval)
```

> [!WARNING]
> Running `tofu apply` incurs monthly/hourly VPS charges. Modifying `admin_password` forces recreation of the VPS instance. State is stored locally in `terraform.tfstate` (excluded by [.gitignore](.gitignore)).

## NixOS Installation via Rescue ISO

Boot the custom minimal NixOS ISO through ConoHa API rescue mode:

```bash
# 1. Provision base instance (Debian bootstrap)
tofu apply

# 2. Inject NixOS installer ISO and boot into rescue mode
./scripts/nixos-iso.ysh install <instance_id> ../result-iso/iso/nixos-*.iso

# 3. Connect via ConoHa VNC Console, configure network, partition, and install NixOS
#    (See hosts/torii-chan/install-nixos.sh)

# 4. Eject installer ISO and reboot into installed NixOS system
./scripts/nixos-iso.ysh eject <instance_id>

# 5. Extract public IP and apply NixOS configuration over SSH
tofu output -json torii_chan_addresses
```

### ISO Helper Tool ([scripts/nixos-iso.ysh](scripts/nixos-iso.ysh))

| Subcommand | Function |
| :--- | :--- |
| `install <instance_id> <iso_path>` | Uploads ISO to Glance Image API, stops server, attaches rescue ISO, and starts VM. |
| `eject <instance_id>` | Stops server, terminates rescue mode, and reboots VM from root disk. |
| `status <instance_id>` | Queries OpenStack Nova instance state, task status, and IP addresses. |

## References

- VPS failover & recovery runbook: [docs/operations/vps-failover.md](../docs/operations/vps-failover.md)
- Network topology: [docs/architecture/network-topology.md](../docs/architecture/network-topology.md)
