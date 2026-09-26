_:

{
  services = {
    # TLP owns CPU, PCIe and USB power management; nixos-hardware pulls it in
    # via common/pc/laptop, which excludes power-profiles-daemon and tuned.
    tlp = {
      enable = true;

      # Noctalia's power_profile widget reads net.hadess.PowerProfiles, an
      # interface only power-profiles-daemon otherwise provides. tlp-pd serves
      # the same interface backed by TLP, and nixpkgs asserts the two cannot
      # coexist, so this is the only way to keep TLP and that widget working.
      pd.enable = true;

      # 75/80 trades roughly 20% of runtime for slower capacity loss on a
      # battery that lives on AC. `sudo tlp fullcharge` lifts it to 100% until
      # the charger is next unplugged.
      settings = {
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    # nixos-hardware enables throttled but leaves upstream's project defaults,
    # which its README calls "not recommendations for every system". The limits
    # below are resized to this chassis; per-value notes are inline.
    #
    # throttled compares config mtimes to honour Autoreload, but NixOS pins
    # store paths to the epoch, so the comparison never sees a change: restart
    # throttled.service after editing these values.
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
      # i7-8565U configurable TDP-up; upstream's 44 W is past what one fan
      # cools, so the CPU held the 95 C trip and lost frequency anyway.
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

    # HybridSleep writes a hibernation image to swap, and this host had
    # swapDevices = [] (see hardware.nix), so the action could not run at all.
    # Promote to "Hibernate" once a hibernation test has passed.
    upower.criticalPowerAction = "PowerOff";
  };

  # Hibernation needs no boot.resumeDevice here. On UEFI, systemd-sleep picks a
  # swap space and records it in the HibernateLocation EFI variable, which
  # systemd-hibernate-resume reads on the next boot. Naming the root partition
  # instead adds `resume=` for a device that holds no swap itself (the swap is a
  # file inside it), and logind then refuses to hibernate.
}
