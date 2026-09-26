_:

{
  services = {
    # nixos-hardware pulls TLP in via common/pc/laptop, which excludes
    # power-profiles-daemon and tuned.
    tlp = {
      enable = true;

      # Noctalia's widget needs net.hadess.PowerProfiles, which tlp-pd provides
      # over TLP; nixpkgs forbids it alongside power-profiles-daemon.
      pd.enable = true;

      # Trades ~20% runtime for slower wear on a battery that lives on AC;
      # `sudo tlp fullcharge` lifts it to 100% until the next unplug.
      settings = {
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    # Restart throttled.service after editing these: Autoreload compares config
    # mtimes, and NixOS pins store paths to the epoch, so it never fires.
    # Upstream's 44 W / 95 C defaults are replaced by this chassis' limits.
    throttled.extraConfig = ''
      [GENERAL]
      Enabled: True
      Sysfs_Power_Path: /sys/class/power_supply/AC*/online
      Autoreload: True

      [BATTERY]
      Update_Rate_s: 30
      # i7-8565U base TDP
      PL1_Tdp_W: 15
      PL1_Duration_s: 28
      PL2_Tdp_W: 25
      PL2_Duration_S: 0.002
      Trip_Temp_C: 85
      cTDP: 0
      Disable_BDPROCHOT: False

      [AC]
      Update_Rate_s: 5
      # i7-8565U configurable TDP-up
      PL1_Tdp_W: 25
      PL1_Duration_s: 28
      PL2_Tdp_W: 35
      PL2_Duration_S: 0.002
      Trip_Temp_C: 90
      cTDP: 0
      # Keeps the EC's own 80 C throttle; enabling this runs hotter.
      Disable_BDPROCHOT: False

      # Offsets must be negative to undervolt, and firmware locks the voltage
      # interface on Whiskey Lake, so these stay at 0.
      [UNDERVOLT.AC]
      CORE: 0
      GPU: 0
      CACHE: 0
      UNCORE: 0
      ANALOGIO: 0

      [UNDERVOLT.BATTERY]
      CORE: 0
      GPU: 0
      CACHE: 0
      UNCORE: 0
      ANALOGIO: 0
    '';

    # Suspending at a critical battery would drain what is left; hibernating
    # preserves the session in the swapfile and powers off.
    upower.criticalPowerAction = "Hibernate";
  };

  # No boot.resumeDevice: it would put `resume=` on the kernel command line for
  # a partition that holds no swap itself. systemd-sleep picks the swapfile on
  # UEFI and records it in the HibernateLocation EFI variable.
}
