# System Packages (`nixos/environment/`)

Modular system-wide package groups enabled via `my.packages.*` options.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [base.nix](base.nix) | System administration essentials (`file`, `git`, `tmux`, `vim`, `which`) and `zsh` as the default user shell. | `my.packages.core.enable` (default: `true`) |
| [monitoring.nix](monitoring.nix) | Performance and hardware monitoring (e.g. `btop`, `htop`, `fastfetch`, `lm_sensors`, `pciutils`, `usbutils`). | `my.packages.monitoring.enable` (default: `true`) |
| [network-tools.nix](network-tools.nix) | Network diagnostics and transfer tools (e.g. `cloudflared`, `curl`, `dnsutils`, `mtr`, `nebula`, `nmap`, `rsync`, `tcpdump`, `xh`). | `my.packages.network-tools.enable` (default: `true`) |
| [data.nix](data.nix) | Data processing and compression utilities (`jq`, `p7zip`, `unzip`, `xz`, `yq-go`, `zip`, `zstd`). | `my.packages.data.enable` (default: `true`) |
| [security.nix](security.nix) | Security and encryption utilities (`age`, `gnupg`, `ssh-to-age`). | `my.packages.security.enable` (default: `true`) |
| [default.nix](default.nix) | Declares all `my.packages.*` options and aggregates package group modules. | — |

## Usage Example

```nix
my.packages = {
  monitoring.enable = true;
  network-tools.enable = true;
  data.enable = true;
};
```

## References

- NixOS system modules aggregator: [nixos/default.nix](../default.nix)
- Custom module options (`my.*`): [docs/architecture/flake-and-modules.md](../../docs/architecture/flake-and-modules.md)
- User environment package configuration: [home/programs/](../../home/programs/README.md)
