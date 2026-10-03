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

        # XanMod builds with CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y.
        # Under intel_pstate (active mode), governor "performance" forces EPP
        # to "performance" and rejects EPP writes with EBUSY. Setting "powersave"
        # on both AC and BAT allows HWP to follow EPP hints properly.
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
        CPU_ENERGY_PERF_POLICY_ON_SAV = "power";

        # Dynamic boost raises performance on AC during sudden load spikes.
        CPU_HWP_DYN_BOOST_ON_AC = 1;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;

        # Keep AC fan curve gentle by default; Noctalia's widget can lift it to performance.
        PLATFORM_PROFILE_ON_AC = "balanced";
        PLATFORM_PROFILE_ON_BAT = "balanced";
        PLATFORM_PROFILE_ON_SAV = "low-power";

        PCIE_ASPM_ON_BAT = "powersave";
      };
    };

    # Restart throttled.service after editing these: Nix store paths never
    # change mtimes, so Autoreload never triggers. Full rationale lives in README.md.
    throttled.extraConfig = ''
      [GENERAL]
      Enabled: True
      Sysfs_Power_Path: /sys/class/power_supply/AC*/online
      Autoreload: True

      [AC]
      Update_Rate_s: 5
      # Core i7-8565U configurable TDP-up
      PL1_Tdp_W: 25
      PL1_Duration_s: 28
      # Short-term burst limit for UI and build responsiveness
      PL2_Tdp_W: 35
      PL2_Duration_S: 0.002
      # Allows burst headroom below TjMax (100 C)
      Trip_Temp_C: 90

      [BATTERY]
      Update_Rate_s: 30
      # Core i7-8565U nominal TDP
      PL1_Tdp_W: 15
      PL1_Duration_s: 28
      PL2_Tdp_W: 25
      PL2_Duration_S: 0.002
      Trip_Temp_C: 85
    '';

    # Suspending at a critical battery would drain what is left; hibernating
    # preserves the session in the swapfile and powers off.
    upower.criticalPowerAction = "Hibernate";
  };

  # No boot.resumeDevice: it would put `resume=` on the kernel command line for
  # a partition that holds no swap itself. systemd-sleep picks the swapfile on
  # UEFI and records it in the HibernateLocation EFI variable.
}
