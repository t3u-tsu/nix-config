# System Packages (`nixos/environment/`)

Modular system-wide package groups enabled via `my.packages.*` options.

## Package Groups

| Module | Purpose | Option | Default |
| :--- | :--- | :--- | :--- |
| `base.nix` | System administration essentials (`file`, `git`, `tmux`, `vim`, `which`) and zsh as the default shell. | `my.packages.core.enable` | `true` |
| `monitoring.nix` | Performance and hardware monitoring (`btop`, `htop`, `fastfetch`, `lm_sensors`, `pciutils`, `usbutils`, etc.). | `my.packages.monitoring.enable` | `true` |
| `network-tools.nix` | Network diagnostics and transfer tools (`cloudflared`, `curl`, `dnsutils`, `mtr`, `nebula`, `nmap`, `rsync`, `tcpdump`, `xh`, etc.). | `my.packages.network-tools.enable` | `true` |
| `data.nix` | Data processing and compression utilities (`jq`, `p7zip`, `unzip`, `xz`, `yq-go`, `zip`, `zstd`). | `my.packages.data.enable` | `true` |
| `security.nix` | Security and encryption utilities (`age`, `gnupg`, `sops`, `ssh-to-age`). | `my.packages.security.enable` | `true` |
| `default.nix` | Declares all `my.packages.*` options. | — | — |

## Usage Example

```nix
my.packages = {
  monitoring.enable = true;
  network-tools.enable = true;
  data.enable = true;
};
```
