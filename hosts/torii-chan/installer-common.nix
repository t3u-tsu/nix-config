# Common settings for the "installer" stage, shared by the SBC SD image
# (sd-installer.nix) and the VPS installer ISO (vps-installer.nix): production
# gateway services and SOPS-managed password hashes are not used, login is by a
# temporary password (injected by build-*.sh in an --impure build) or public key.
{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.my.installer;
  username = config.my.user.name;
  hostKey = config.my.hostKey;

  # Temporary password hash passed by build-*.sh as an environment variable in an
  # --impure build; empty in a pure build, so no temporary password is set.
  envTempPasswordHash = builtins.getEnv "TORII_INSTALLER_TEMP_PASSWORD_HASH";
  tempPasswordHash =
    if envTempPasswordHash != "" then envTempPasswordHash else cfg.temporaryPasswordHash;
in
{
  options.my.installer = {
    enable = mkEnableOption "installer stage: temporary provisioning without production services";

    # Both installers must present the production hostname: my.hostKey (the SOPS
    # secret prefix) derives from networking.hostName.
    hostName = mkOption {
      type = types.str;
      default = "torii-chan";
      description = "Hostname used by the installer environment.";
    };

    temporaryPasswordHash = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Temporary password hash (SHA-512) for the installer environment.
        Usually injected by build-*.sh via TORII_INSTALLER_TEMP_PASSWORD_HASH
        (nix build --impure). When null, no password is set (SSH key only).
      '';
    };

    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [
        # t3u's public key (public data, no private key committed)
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
      ];
      description = "SSH public keys for the installer root user.";
    };

    allowPasswordAuthentication = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Allow SSH password authentication. LAN-only installers (SBC) can enable
        this for convenience together with the temporary password; installers
        exposed to the internet (VPS) should keep it disabled (key-only).
      '';
    };

    firewallOpenPorts = mkOption {
      type = types.listOf types.int;
      default = [ 22 ];
      description = "TCP ports opened by the installer firewall.";
    };
  };

  config = mkIf cfg.enable {
    # The gateway profile sets my.services.gateway.enable = true, so it needs
    # mkForce to stay off in the installer (Nebula / DDNS / NAT are not run).
    my.services.gateway.enable = lib.mkForce false;

    networking.hostName = cfg.hostName;

    networking.firewall = {
      enable = true;
      allowedTCPPorts = cfg.firewallOpenPorts;
      allowedUDPPorts = [ ];
      logRefusedConnections = false;
    };

    # Login with root's authorizedKeys, plus the temporary password when one is set.
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = cfg.allowPasswordAuthentication;
        KbdInteractiveAuthentication = false;
      };
    };

    # The production password hashes must NOT be baked into the installer, so
    # neededForUsers is off (no decryption at boot) and the live users get the
    # temporary password instead. Production switches back to the normal
    # nixos-rebuild path with the SOPS-managed hashedPasswordFile.
    sops.secrets = {
      "${hostKey}_${username}_password_hash".neededForUsers = lib.mkForce false;
      "${hostKey}_root_password_hash".neededForUsers = lib.mkForce false;
    };

    users.users = {
      root = {
        openssh.authorizedKeys.keys = cfg.authorizedKeys;
        hashedPasswordFile = lib.mkForce null;
        hashedPassword = lib.mkIf (tempPasswordHash != null) (lib.mkForce tempPasswordHash);
      };
      ${username} = {
        hashedPasswordFile = lib.mkForce null;
        hashedPassword = lib.mkIf (tempPasswordHash != null) (lib.mkForce tempPasswordHash);
      };
    };
  };
}
