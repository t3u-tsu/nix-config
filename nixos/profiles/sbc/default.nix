{ lib, ... }:
{
  config = {
    # Disable Nix sandboxing and seccomp filtering for legacy kernels
    # lacking namespace/BPF support
    nix.settings = {
      sandbox = false;
      filter-syscalls = false;
    };

    swapDevices = [
      {
        device = "/var/lib/swapfile";
        size = 4096;
      }
    ];

    boot.kernel.sysctl = {
      "vm.swappiness" = 10;
    };
  };
}
