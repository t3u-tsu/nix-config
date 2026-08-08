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
        size = 4096; # 4GB
      }
    ];

    boot.kernel.sysctl = {
      "vm.swappiness" = 10;
    };

    my = {
      # Common SBC user configuration (base/user.nix handles users.*)
      user.authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
      ];

    };
  };
}
