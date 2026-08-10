# hosts/torii-chan/vps-installer.nix - Custom NixOS installer ISO configuration for a ConoHa VPS (512MB)
#
# NixOS module that produces an "installer ISO operable over SSH" for installing
# NixOS on torii-chan's failover VPS (ConoHa VPS g2l-t-c1m512 = 1 vCPU / 512MB RAM
# / 30GB volume, x86_64).
#
# Shares the stage: installer common settings (installer-common.nix) with
# sd-installer.nix (SBC SD image). This module only covers the VPS-specific bits:
#   - ISO format (image.modules."iso-installer")
#   - Static IP configuration (ConoHa has no DHCP; the IP is set via conoha.installer.wan)
#   - Low-memory settings for 512MB (zram, serial console, OOM mitigation)
#   - install-nixos, a nixos-install automation script (bundled and added to PATH)
#
# Authentication handling (temporary password / SSH public keys / SOPS separation /
# production services disabled) is provided by installer-common.nix. Since the VPS
# is directly exposed on a public IP, SSH is key-only.
#
# Build (temporary password auto-issued):
#   ./hosts/torii-chan/build-vps-iso.sh
#   (Not registered in nixosConfigurations; exposed only as a package because
#    nix flake check would fail verifying the ISO as a normal bootable system)
#
# The static IP is only known after `terraform apply`, so if it is not set yet,
# build with conoha.installer.wan.ipv4 left null and configure it manually after
# boot with `install-nixos.sh network`.
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

  # NOTE: do not import installation-cd-base.nix directly.
  # system.build.images.iso-installer is attached automatically via image.modules
  # (nixpkgs/modules/image/images.nix, image.format = "iso-installer").
  # Importing it directly defines system.build.image at the top level and triggers
  # a warning about it conflicting with system.build.images (build.image vs images).
  # Configure isoImage.* via image.modules."iso-installer" (below).

  options.conoha.installer = {
    hostName = lib.mkOption {
      type = lib.types.str;
      default = "torii-chan";
      description = "Hostname of the installer (live environment).";
    };

    # Networking. ConoHa VPS does not provide DHCP, so static configuration is the norm.
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
          is configured manually after boot with `install-nixos.sh network`.
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

    install = {
      disk = lib.mkOption {
        type = lib.types.str;
        default = "/dev/vda";
        description = ''
          Target disk for the installation (default for install-nixos.sh).
          ConoHa's 30GB boot volume is usually /dev/vda.
        '';
      };

      swapSize = lib.mkOption {
        type = lib.types.str;
        default = "1G";
        description = "Size of the swap file created during installation.";
      };
    };
  };

  config = {
    # --- Installer common (installer-common.nix) ---
    # Provides production-service disabling / temporary password / SOPS separation /
    # sshd settings. The temporary password is injected by build-vps-iso.sh via
    # TORII_INSTALLER_TEMP_PASSWORD_HASH (nix build --impure). The VPS sits on a
    # public IP, so SSH is key-only.
    my.installer = {
      enable = true;
      allowPasswordAuthentication = false;
    };

    networking.hostName = cfg.hostName;

    # --- Networking (formerly nixos/installer/network.nix) ---
    # ConoHa VPS does not provide DHCP, so the static IP is set explicitly.
    # The IP is only known after `terraform apply` (see torii_chan_addresses in
    # terraform/outputs.tf). If it is unknown at ISO build time, build with
    # conoha.installer.wan.ipv4 = null and fall back to configuring the network
    # manually after boot with `install-nixos.sh network`.
    networking = {
      # Scripted networking (systemd-networkd / NetworkManager are not used)
      useDHCP = false;
      # Treat the virtio NIC as eth0 (disable systemd's predictable naming)
      usePredictableInterfaceNames = false;
      networkmanager.enable = lib.mkForce false; # disabled with mkForce because installation-device.nix enables it

      # Static IP configuration (only effective when wan.ipv4 is set)
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

    # Build-time warning when no static IP is set (manual setup from the VNC console
    # will be needed)
    warnings = lib.optional (cfg.wan.ipv4 == null) ''
      conoha.installer.wan.ipv4 is not set. This ISO has no static IP, so to connect
      over SSH, configure the network after boot from the VNC console by running:
        install-nixos.sh network
      Alternatively, finalize the IP after terraform apply and rebuild the ISO.
    '';

    # --- ISO volume label / boot menu name ---
    image.modules."iso-installer" = {
      isoImage = {
        volumeID = "conoha-installer";
        appendToMenuLabel = " ConoHa Installer";
      };
    };

    # --- Low-memory tuning (formerly nixos/installer/memory.nix) ---
    # The live environment's /nix/store is a squashfs + tmpfs overlay, and cache
    # extraction during nixos-install consumes RAM. OOM is likely at 512MB, so zram
    # absorbs memory pressure and swap is used aggressively.
    zramSwap = {
      enable = true;
      algorithm = "lz4"; # fast compression algorithm for a single vCPU (default is zstd)
      memoryPercent = 50;
      priority = 100; # prefer zram over disk swap
    };

    boot.kernel.sysctl = {
      # Aggressively evict spare RAM to zram to prevent OOM
      "vm.swappiness" = 100;
    };

    # Kernel parameters for headless (VNC / serial) consoles.
    # console=ttyS0 enables the serial console; nomodeset ensures text renders
    # over VNC.
    boot.kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
      "nomodeset"
    ];

    # --- Installation helper tools ---
    # nixos-install / nixos-generate-config / parted / gptfdisk are already included
    # in the standard installer ISO (installer/tools/tools.nix and profiles/base.nix
    # in module-list.nix), so they are not re-added here.
    environment.systemPackages = [
      # Installation automation script (added to PATH as install-nixos)
      (pkgs.writeShellScriptBin "install-nixos" (builtins.readFile ./install-nixos.sh))

      # Tools for manual fallback and file transfer
      pkgs.curl
    ];
  };
}
