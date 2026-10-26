# Common settings for the "installer" stage, shared by the SBC SD image
# (sd-installer.nix) and the VPS installer ISO (vps-installer.nix): production
# gateway services and agenix-managed password hashes are not used, login is by a
# temporary password (injected by build-*.ysh in an --impure build) or public key.
{
  config,
  lib,
  ...
}:

let
  cfg = config.my.installer;
  username = config.my.user.name;

  # Temporary password hash passed by build-*.ysh as an environment variable in an
  # --impure build; empty in a pure build, so no temporary password is set.
  envTempPasswordHash = builtins.getEnv "TORII_INSTALLER_TEMP_PASSWORD_HASH";
  tempPasswordHash =
    if envTempPasswordHash != "" then envTempPasswordHash else cfg.temporaryPasswordHash;
in
{
  options.my.installer = {
    enable = lib.mkEnableOption "installer stage: temporary provisioning without production services";

    # Both installers must present the production hostname: the agenix secret
    # paths derive from networking.hostName.
    hostName = lib.mkOption {
      type = lib.types.str;
      default = "torii-chan";
      description = "Hostname used by the installer environment.";
    };

    temporaryPasswordHash = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Temporary password hash (SHA-512) for the installer environment.
        Usually injected by build-*.ysh via TORII_INSTALLER_TEMP_PASSWORD_HASH
        (nix build --impure). When null, no password is set (SSH key only).
      '';
    };

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = config.my.user.authorizedKeys;
      description = "SSH public keys for the installer root user.";
    };

    allowPasswordAuthentication = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Allow SSH password authentication. LAN-only installers (SBC) can enable
        this for convenience together with the temporary password; installers
        exposed to the internet (VPS) should keep it disabled (key-only).
      '';
    };

    firewallOpenPorts = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [ 22 ];
      description = "TCP ports opened by the installer firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
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

    # hosts/torii-chan/default.nix sets the production host key, so the installer
    # forces agenix-rekey's sentinel hostPubkey to skip rekeying. Enabled secrets
    # would become placeholders; the production services above stay off.
    age.rekey.hostPubkey = lib.mkForce "age1qyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqs3290gq";

    my.services.emergencySsh.enable = lib.mkForce false;

    # Production credentials must not be baked into the installer: disable the
    # agenix secrets and give the live users the temporary password instead.
    age.secrets = {
      deploy_key.enable = lib.mkForce false;
      user_password_hash.enable = lib.mkForce false;
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
