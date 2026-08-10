# nixos/profiles/sbc/default.nix - Profile for SBC devices (e.g., Orange Pi Zero 3)
{ lib, ... }:
{
  config = {
    # Disable Nix sandboxing and seccomp filtering for legacy kernels
    # lacking namespace/BPF support
    nix.settings = {
      sandbox = false;
      filter-syscalls = false;
    };

    # Swap configuration for stable builds on low-RAM devices
    swapDevices = [
      {
        device = "/var/lib/swapfile";
        size = 4096;
      }
    ];

    boot.kernel.sysctl = {
      "vm.swappiness" = 10;
    };

    # SSH authorized keys for torii-chan live in the shared gateway profile
    # (see nixos/profiles/gateway/default.nix), so the SBC and failover VPS
    # both get the same operator access.
  };
}
