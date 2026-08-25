{ lib, ... }:

with lib;

{
  options.my.services.gateway = {
    enable = mkEnableOption "torii-chan role: Nebula gateway + DDNS + Minecraft forward";

    wanInterface = mkOption {
      type = types.str;
      default = "end0";
      description = "Name of the external / WAN interface used for NAT";
    };

    restrictAccess = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Expose only TCP 25565 (Minecraft) on the WAN and allow SSH only via
        the Nebula mesh. Set to false (with mkForce) during SD provisioning.
      '';
    };
  };

  imports = [
    ./firewall.nix
    ./hardening.nix
    ./nebula.nix
    ./ssh.nix
    ./ddns.nix
  ];
}
