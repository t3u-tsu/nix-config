# OpenTofu: ConoHa VPS Resource Management

Declarative OpenTofu configuration to provision torii-chan's failover VPS on
**ConoHa VPS** (GMO).

## Prerequisites

- Use `tofu` inside the development shell (`nix develop`)
- Provider: [gmo-internet/conohavps](https://registry.terraform.io/providers/gmo-internet/conohavps/latest) (beta)
- Credentials: ConoHa API user (stored in `secrets/services/conoha-vps-mcp.yaml` via SOPS)

## Injecting credentials

Credentials are read from environment variables (never write them in plain text in files).

```bash
# Inject ConoHa API credentials from SOPS
export CONOHAVPS_USER_ID=$(sops -d --extract '["OPENSTACK_USER_ID"]' secrets/services/conoha-vps-mcp.yaml)
export CONOHAVPS_PASSWORD=[redacted]
export CONOHAVPS_TENANT_ID=$(sops -d --extract '["OPENSTACK_TENANT_ID"]' secrets/services/conoha-vps-mcp.yaml)
# Region is optional (default c3j1). The provider also reads CONOHAVPS_REGION.
```

Required variables (passed via `TF_VAR_*`):

```bash
export TF_VAR_admin_password="[redacted]"
export TF_VAR_ssh_public_key='ssh-ed25519 AAAA... t3u@BrokenPC'  # same key as vps.nix
```

## Usage

```bash
cd terraform
tofu init     # fetch provider (first run)
tofu fmt      # format
tofu validate # syntax check
tofu plan     # review the change plan
tofu apply    # apply (creates a VPS -> incurs cost. Requires user approval before running)
tofu output -json torii_chan_addresses   # check assigned IPs (for wanIp)
tofu destroy  # delete all resources (stops billing. Requires approval)
```

- Variable defaults live in `variables.tf` (512MB plan / 30GB boot volume / Debian 12 placeholder OS)
- `.terraform.lock.hcl` is committed (pins provider versions)
- State is **local** (`terraform.tfstate`, excluded via `.gitignore`).
  Remote backend is not used because ConoHa object storage (S3-compatible API)
  requires a capacity contract

## State management (local)

The state file (`terraform.tfstate`) is stored locally and excluded via `.gitignore` (not committed).

- Assumes **single-operator, single-host** operation
- **Backup**: copy `terraform.tfstate` before `tofu apply`
  (e.g. `cp terraform.tfstate terraform.tfstate.bak`)
- **ConoHa object storage S3 backend is not used** (skipped because it requires
  a capacity contract). If needed later, add `backend.tf` and migrate with
  `tofu init -migrate-state`

## Resources

- `conohavps_keypair.t3u` — SSH keypair (shared t3u public key across hosts)
- `conohavps_securitygroup.torii_chan` + rules — 22/tcp, 4242/udp (Nebula Lighthouse), ICMP, egress allow all
- `conohavps_volume.boot` — 30GB boot volume (`c3j1-ds02-boot`, Debian 12 provisioned)
- `conohavps_instance.torii_chan` — 512MB plan (`g2l-t-c1m512`)

## NixOS install workflow

ConoHa's standard OS images do not include NixOS, so we use the **rescue ISO injection**
method to replace the disk with NixOS (nixos-anywhere is not possible on the 512MB plan).

```bash
# 1. Create the VPS (Debian boot)
tofu apply

# 2. Verify SSH reachability to Debian (keypair installed)
ssh -i ~/.ssh/t3u root@<public_ip>

# 3. Fetch the NixOS minimal ISO and inject it for a rescue boot
./scripts/nixos-iso.sh install <instance_id> ./nixos-minimal.iso

# 4. Operate the NixOS installer via the VNC console in the ConoHa control panel
#    (set a static IP -> parted/mkfs -> nixos-generate-config -> nixos-install.
#     See hosts/torii-chan/README.md for details)

# 5. After installation, eject the ISO and boot normally
./scripts/nixos-iso.sh eject <instance_id>

# 6. Reflect the assigned IPs into wanIp / wanGateway in vps.nix and apply NixOS
tofu output -json torii_chan_addresses
```

`scripts/nixos-iso.sh` talks directly to the ConoHa public API (creates and uploads an
ISO via the Image API, and inserts/ejects it via the Compute API `rescue`/`unrescue`).

Subcommands:
- `install <instance_id> <iso_file>` — create/upload the ISO, stop the server, inject via rescue, then start
- `eject <instance_id>` — stop the server, unrescue (eject ISO), then start
- `status <instance_id>` — check instance state (status / vm_state / task_state / addresses)

Edge cases:
- If the server is already stopped, tolerate the `os-stop` 409 and continue (idempotent)
- On API errors, print the response body (easy to diagnose)
- The state-transition wait timeout is adjustable via the `CONOHAVPS_WAIT_TIMEOUT` env var (default 600s)

## Notes

- **Beta provider**: features/schema may change without notice
- **Cost**: the 512MB plan costs ¥459/month. `apply` starts billing immediately
- **admin_pass changes recreate the instance** (force new), so settle it before applying
- **On destroy**: volumes, security groups, and keypairs are also deleted (watch out for leftover resources after instance deletion)
