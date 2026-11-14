# Host Installation & Provisioning (`scripts/install/`)

Bootstrap scripts executed on target machines during initial NixOS installation or emergency recovery.

## Overview

When installing NixOS on a new machine (from a live USB or rescue image), these scripts prepare host credentials before `nixos-install` or `nixos-rebuild switch`:

| Script | Purpose | Typical Environment |
| :--- | :--- | :--- |
| [init-host-key.sh](init-host-key.sh) / [init-host-key.ysh](init-host-key.ysh) | Generate host SSH key in `<target_root>/etc/ssh/` for `age.rekey.hostPubkey` | Live installer / Rescue ISO |
| [setup-deploy-key.sh](setup-deploy-key.sh) / [setup-deploy-key.ysh](setup-deploy-key.ysh) | Decrypt private flake deploy key and configure GitHub SSH alias | Target machine under installation |

## Architecture: Why `.sh` and `.ysh` Pairs Exist

Minimal rescue environments and standard NixOS minimal installer ISOs do not have Oils (`ysh`) pre-installed.

1. **`.sh` Wrapper (Bootstrap Entry Point)**:
   - Written in portable Bash (`set -euo pipefail`).
   - Checks whether the tools the paired `.ysh` script needs (`ysh` plus `ssh-keygen`, and `age` for [setup-deploy-key.ysh](setup-deploy-key.ysh)) are present in `PATH`.
   - If missing, launches `nix-shell -p oils-for-unix ...` on the fly to provide a transient runtime.
   - Execs the corresponding `.ysh` script transparently.

2. **`.ysh` Implementation (Core Logic)**:
   - Contains the actual validation and generation logic written in Oils YSH.
   - Can be run directly when `ysh` is already installed.

## Usage

### 1. Initialize Host Key

Run after mounting the target filesystem to `/mnt`:

```bash
# From live installer environment:
scripts/install/init-host-key.sh /mnt

# Prints the host public key:
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... root@hostname
```

Add the printed public key to `hosts/<hostname>/default.nix` under `age.rekey.hostPubkey`, then run `just secret rekey` on your workstation.

### 2. Set Up Deploy Key

Run on the target machine when private flake inputs (`nix-config-private`) need to be fetched during `nixos-install`:

```bash
# Decrypts deploy key using the target host key and registers github-nix-config-private:
scripts/install/setup-deploy-key.sh <hostname> /mnt
```

## References

- Host addition runbook: [docs/operations/adding-a-host.md](../../docs/operations/adding-a-host.md)
- Scripts directory index: [scripts/README.md](../README.md)
