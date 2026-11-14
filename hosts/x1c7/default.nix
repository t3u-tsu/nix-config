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
    # Brings in services.throttled and TLP (configured in services/power.nix).
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
  ];

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDEWwvK68f2ofCLbl6W1v5O7dL5Xe9YGhK7HS5aX+2rZ";

  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod;

    loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
    loader.efi.canTouchEfiVariables = true;
  };

  networking.hostName = "x1c7";

  # Power and thermal management lives in services/power.nix.
  services = {
    logind.settings.Login.HandleLidSwitchExternalPower = "lock";

    fprintd.enable = true;
    fwupd.enable = true;

    udev.extraRules = ''
      # Keep Synaptics fingerprint reader awake; force power/persist=0 so libfprint handles unplug/replug cleanly.
      ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="00bd", ATTR{power/control}="on", ATTR{power/persist}="0"
    '';
  };

  systemd.services = {
    fprintd.serviceConfig = {
      # Wait for USB re-enumeration on resume before D-Bus activation probes devices.
      ExecStartPre = "${config.systemd.package}/bin/udevadm settle --timeout=5";
      # Bound fprint_device_release()'s nested main loop if a stale USB handle hangs on stop.
      TimeoutStopSec = "5s";
    };

    # Stop fprintd before sleep so active lock-screen claims do not cross USB re-enumeration.
    fprintd-pre-sleep = {
      description = "Stop fprintd before sleep";
      before = [ "sleep.target" ];
      wantedBy = [ "sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${config.systemd.package}/bin/systemctl stop fprintd.service";
      };
    };
  };

  # Enabled ahead of a possible LUKS migration; nothing on this host uses the
  # TPM yet.
  security.tpm2.enable = true;

  # Place pam_fprintd ahead of pam_unix (default order) with up to 3 tries
  # and a 5s timeout, falling back to password on failure or expiration.
  security.pam.services = lib.genAttrs [ "polkit-1" "sudo" ] (_name: {
    rules.auth.fprintd = {
      settings = {
        max-tries = 3;
        timeout = 5;
      };
    };
  });

  my.services.desktop = {
    greetd = {
      greeterOutput.name = "eDP-1";
      greeterWallpaper = "${
        config.users.users.${config.my.user.name}.home
      }/Pictures/wallpapers/PTITSA/144133008_p0.jpg";
    };
    bluetooth.experimental = true;
  };

  home-manager.users.${config.my.user.name} = {
    # Home-manager secrets are decrypted with the user's ~/.ssh/id_ed25519,
    # so agenix needs that public key, not the host key.
    age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcgVKvJVkA7KBmdO7ogwb5v9f1qUGOCiKu1CHpOLjYU";
    my.home.desktop = {
      noctalia.wallpaperPreset = "minimal";

      media.enable = true;
      creative.enable = true;
      dev-tools.ai-tools.enable = true;
      dev-tools.hardware.enable = true;
    };
  };
}
