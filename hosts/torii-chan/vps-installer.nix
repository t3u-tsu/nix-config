# SSH-operable NixOS installer ISO for torii-chan's failover VPS (ConoHa
# g2l-t-c1m512 = 1 vCPU / 512MB / 30GB, x86_64): the VPS-specific layer on top of
# installer-common.nix, adding the ISO format, static IP (ConoHa has no DHCP),
# 512MB low-memory tuning and the `install-nixos` helper on PATH. SSH is key-only.
#
# Build: ./hosts/torii-chan/build-vps-iso.sh. A package, not a nixosConfiguration:
# `nix flake check` cannot verify an installer ISO as a bootable system.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.conoha.installer;
in
{
  imports = [
    ./installer-common.nix
  ];

  # Do NOT import installation-cd-base.nix directly: it defines
  # system.build.image at the top level and warns about conflicting with
  # system.build.images. image.format = "iso-installer" already attaches
  # system.build.images.iso-installer; configure isoImage.* via image.modules.

  options.conoha.installer = {
    interface = lib.mkOption {
      type = lib.types.str;
      default = "eth0";
      description = ''
        Network interface used by the installer.
        ConoHa VPS uses a virtio NIC with predictable interface naming disabled,
        so it is usually eth0. Check with `ip link` after boot and change this if
        the name differs.
      '';
    };

    wan = {
      ipv4 = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "203.0.113.10";
        description = ''
          IPv4 address assigned by ConoHa.
          Check it after `terraform apply` with
          `terraform output -json torii_chan_addresses` and set it here. Building
          with null leaves the static IP unset and switches to the mode where it
          is configured manually after boot with `install-nixos network`.
        '';
      };

      prefixLength = lib.mkOption {
        type = lib.types.int;
        default = 24;
        example = 32;
        description = "IPv4 address prefix length; set it to match the allocation from ConoHa.";
      };

      gateway = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "203.0.113.1";
        description = "IPv4 address of the default gateway.";
      };

      nameservers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        description = "List of DNS nameservers.";
      };
    };
  };

  config = {
    # Production services / temporary password / sshd settings come from
    # installer-common.nix; the VPS sits on a public IP, so SSH is key-only.
    my.installer = {
      enable = true;
      allowPasswordAuthentication = false;
    };

    # ConoHa VPS provides no DHCP, and the static IP is only known after
    # `terraform apply` (terraform/outputs.tf), so wan.ipv4 can still be null at
    # ISO build time - configure it after boot with `install-nixos network`.
    networking = {
      useDHCP = false;
      # The virtio NIC must be eth0, not an enp* predictable name.
      usePredictableInterfaceNames = false;
      # installation-device.nix enables NetworkManager; mkForce turns it back off.
      networkmanager.enable = lib.mkForce false;

      interfaces.${cfg.interface} = lib.mkIf (cfg.wan.ipv4 != null) {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = cfg.wan.ipv4;
            prefixLength = cfg.wan.prefixLength;
          }
        ];
      };

      defaultGateway = lib.mkIf (cfg.wan.gateway != null) cfg.wan.gateway;
      nameservers = cfg.wan.nameservers;
    };

    warnings = lib.optional (cfg.wan.ipv4 == null) ''
      conoha.installer.wan.ipv4 is not set. This ISO has no static IP, so to connect
      over SSH, configure the network after boot from the VNC console by running:
        install-nixos network
      Alternatively, finalize the IP after terraform apply and rebuild the ISO.
    '';

    image.modules."iso-installer" = {
      isoImage = {
        volumeID = "conoha-installer";
        appendToMenuLabel = " ConoHa Installer";
      };
    };

    # The live /nix/store is a squashfs + tmpfs overlay, and extracting the
    # closure during nixos-install eats RAM: 512MB OOMs without zram + swap.
    zramSwap = {
      enable = true;
      algorithm = "lz4"; # single vCPU: cheaper than the zstd default
      memoryPercent = 50;
      priority = 100; # rank zram above disk swap
    };

    boot.kernel.sysctl = {
      "vm.swappiness" = 100; # evict aggressively to zram before the disk swap
    };

    # console=ttyS0 for the serial console; nomodeset keeps text rendering
    # working over VNC on a headless build.
    boot.kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
      "nomodeset"
    ];

    # nixos-install / nixos-generate-config / parted / gptfdisk already come with
    # the standard installer profile, so only these extras are added.
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "install-nixos" (builtins.readFile ./install-nixos.sh))
      pkgs.curl
    ];
  };
}
