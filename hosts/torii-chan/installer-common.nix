# Common settings for the installer (stage: installer), shared (DRY) by the SBC
# SD image (sd-installer.nix) and the VPS installer ISO (vps-installer.nix).
#
# Inverts the properties of production (stage: production):
#   - Production services (gateway: Nebula / DDNS / NAT) are disabled
#   - Production secrets (SOPS-managed password hashes) are not baked in
#   - Login via a temporary password (injected by build-*.sh in an --impure build)
#     or a public key
#   - sshd tightness is adjusted per platform
#     (SBC = LAN-only, so temporary password + password auth allowed /
#      VPS = public IP, so key-only)
{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.my.installer;
  username = config.my.user.name;
  # Translate the hostname into the SOPS secret name prefix (e.g. "torii-chan" -> "torii_chan").
  hostKey = config.my.hostKey;

  # Temporary password hash passed by build-*.sh as an environment variable in an
  # --impure build. In a normal (pure evaluation) build it is empty and no
  # temporary password is set.
  envTempPasswordHash = builtins.getEnv "TORII_INSTALLER_TEMP_PASSWORD_HASH";
  # Prefer the environment variable (auto-issued); otherwise use the option (manual).
  tempPasswordHash =
    if envTempPasswordHash != "" then envTempPasswordHash else cfg.temporaryPasswordHash;
in
{
  options.my.installer = {
    enable = mkEnableOption "installer stage: temporary provisioning without production services";

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
        # t3u's public key (public information; no private key included)
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
    # --- Disable production services ---
    # hosts/torii-chan/default.nix sets my.services.gateway.enable = true, so it is
    # disabled with mkForce (Nebula / DDNS / NAT are not run).
    my.services.gateway.enable = lib.mkForce false;

    networking.hostName = cfg.hostName;

    # --- Firewall (port 22 only, for provisioning) ---
    networking.firewall = {
      enable = true;
      allowedTCPPorts = cfg.firewallOpenPorts;
      allowedUDPPorts = [ ];
      logRefusedConnections = false;
    };

    # --- SSH (for provisioning) ---
    # The installer bakes the public keys into root's authorizedKeys and also
    # allows login with the temporary password (only when one is set).
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = cfg.allowPasswordAuthentication;
        KbdInteractiveAuthentication = false;
      };
    };

    # --- Temporary password / SOPS separation ---
    # The production password hash (SOPS-managed) is not baked into the installer.
    # neededForUsers is disabled to stop decryption at boot; users in the live
    # environment get the temporary password (only when one is set). After going to
    # production the system switches to the normal nixos-rebuild path (SOPS-managed
    # hashedPasswordFile).
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
