# System Packages

Pre-defined groups of system-level packages that can be toggled via options.

## Options and Categories

Each package category can be enabled individually using the `my.packages.<category>.enable = true` option.

- **`base.nix`**: CLI essentials required for basic system administration. Enabled on all hosts by default.
- **`monitoring.nix`**: System and hardware monitoring tools.
- **`network-tools.nix`**: Network diagnostic and transfer utilities.
- **`data.nix`**: Data processing and compression tools.
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
