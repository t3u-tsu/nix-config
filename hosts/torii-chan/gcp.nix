# GCE platform layer for the shared torii-chan role (Google Cloud on-demand failover).
# Runs on an e2-micro instance (x86_64-linux) in asia-northeast1.
{
  lib,
  modulesPath,
  inputs,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    "${modulesPath}/virtualisation/google-compute-image.nix"
    ../../nixos/profiles/gateway
  ];

  # Disko specification for Google Compute Engine 10GB pd-standard boot disk.
  # Provides system.build.diskoScript for unattended nixos-anywhere bootstrapping.
  disko.devices.disk.main = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # BIOS boot partition for GRUB MBR on GPT
          priority = 1;
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            extraArgs = [
              "-L"
              "nixos"
            ];
          };
        };
      };
    };
  };

  # Let virtualisation/google-compute-image.nix manage fileSystems."/" (autoResize, growfs)
  # to prevent duplicate definition conflicts.
  disko.enableConfig = false;

  # GCE guest configuration disables predictable interface names, naming the primary NIC eth0.
  my.services.gateway.wanInterface = lib.mkDefault "eth0";

  networking = {
    useDHCP = lib.mkDefault true;
    interfaces.eth0.useDHCP = lib.mkDefault true;
  };

  # Low-RAM optimization for 1GB e2-micro instance to prevent OOM during runtime and deployments.
  # Remote deployments should use push-based deploy-rs (flake/deploy.nix) built on the management host.
  zramSwap.enable = false;
  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };
}
