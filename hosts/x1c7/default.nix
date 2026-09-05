{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
    ../../nixos
    # nixos-hardware profile for the exact model (ThinkPad X1 Carbon Gen 7).
    # Pulls in thinkpad (trackpoint) + common/pc/laptop + common/pc/ssd +
    # common/cpu/intel (incl. Intel GPU VAAPI) and enables `services.throttled`.
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
  ];

  # UEFI-only machine; grub with EFI support matches the rest of the fleet
  # (see hosts/BrokenPC, hosts/kagutsuchi-sama). useOSProber picks up a
  # pre-installed Windows partition if present (20QES11500 ships Windows Pro).
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "x1c7";

  # Power / remote administration. The x1-7th-gen module enables `throttled`
  # (Intel CPU throttling/undervolt, the sensible default for Whiskey Lake).
  # The shared common/pc/laptop module also sets tlp via mkDefault unless
  # power-profiles-daemon is enabled, which would make it run alongside
  # throttled — disable tlp so throttled is the single power manager.
  services = {
    tlp.enable = false;

    # Laptop lid behaviour: suspend on battery, lock on AC, ignore when docked.
    logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "lock";
      HandleLidSwitchDocked = "ignore";
    };

    # sshd for remote administration over the Nebula mesh (the desktop profile
    # does not enable it by default). Key-based auth only.
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  my = {
    # Full desktop experience (Niri/Greetd, PipeWire, gaming, dev tools, ...).
    # Drop to the lightweight core by removing this line if the X1 is used for
    # development/office only.
    desktop.full.enable = true;

    services = {
      desktop = {
        greetd.greeterOutput.name = "eDP-1";
        bluetooth.experimental = true;
      };
    };
  };
}
