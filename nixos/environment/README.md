# System Packages

Pre-defined groups of system-level packages that can be toggled via options.

## Options and Categories

Each package category can be enabled individually using the `my.packages.<category>.enable = true` option.

- **`base.nix`**: Core essentials (git, vim, tmux, file, which) required for basic system administration. Enabled on all hosts by default.
- **`monitoring.nix`**: System monitoring tools (btop, fastfetch, lm_sensors) and hardware-specific monitoring tools.
- **`network-tools.nix`**: Network diagnostic and utility tools (curl, wget, nmap, gping, dnsutils).
- **`data.nix`**: Data processing and compression tools (jq, unzip, zip, fd, ripgrep).
- **`security.nix`**: Security-related tools and hardening settings.
- **`default.nix`**: Definition of all `my.packages.*` options.

## Usage Example

To enable specific package groups in a host configuration:

```nix
my.packages = {
  monitoring.enable = true;
  network-tools.enable = true;
  data.enable = true;
};
```
