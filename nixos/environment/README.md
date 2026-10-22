# System Packages (`nixos/environment/`)

Modular system-wide package groups enabled via `my.packages.*` options.

## Package Groups

| Module | Purpose | Option | Default |
| :--- | :--- | :--- | :--- |
| `base.nix` | System administration essentials (curl, git, tmux, vim, tree). | `my.packages.base.enable` | `true` |
| `monitoring.nix` | Performance and hardware monitoring (htop, btop, iotop, nvtop). | `my.packages.monitoring.enable` | `false` |
| `network-tools.nix` | Network diagnostics and transfer tools (bind-utils, nmap, tcpdump, iperf3). | `my.packages.network-tools.enable` | `false` |
| `data.nix` | Data processing and compression utilities (jq, ripgrep, zip, p7zip). | `my.packages.data.enable` | `false` |
| `security.nix` | Security auditing and encryption utilities (nmap, openssl). | `my.packages.security.enable` | `false` |
| `default.nix` | Declares all `my.packages.*` options. | — | — |

## Usage Example

```nix
my.packages = {
  monitoring.enable = true;
  network-tools.enable = true;
  data.enable = true;
};
```
