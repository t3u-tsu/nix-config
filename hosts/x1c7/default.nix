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
      # Keep Synaptics fingerprint reader awake and persistent across power events.
      ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="00bd", ATTR{power/control}="on", ATTR{power/persist}="1"
    '';
  };

  # Enabled ahead of a possible LUKS migration; nothing on this host uses the
  # TPM yet.
  security.tpm2.enable = true;

  # The default stack puts pam_fprintd ahead of pam_unix, which stalls the
  # password prompt for up to 30s. Running fprintd after unix keeps pam_unix
  # prompting (no unix-early here, so use_first_pass must stay off) and lets an
  # empty submission fall through to a single 10s fingerprint attempt.
  security.pam.services = lib.genAttrs [ "polkit-1" "sudo" ] (name: {
    rules.auth.fprintd = {
      order = config.security.pam.services.${name}.rules.auth.unix.order + 10;
      settings = {
        max-tries = 1;
        timeout = 10;
      };
    };
  });

  my.services.desktop = {
    greetd = {
      greeterOutput.name = "eDP-1";
      greeterWallpaper = "/home/${config.my.user.name}/Pictures/wallpapers/PTITSA/144133008_p0.jpg";
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
