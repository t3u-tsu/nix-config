{ lib, ... }:

{
  options.my.services.gateway = {
    enable = lib.mkEnableOption "torii-chan role: Nebula gateway + DDNS + Minecraft forward";

    wanInterface = lib.mkOption {
      type = lib.types.str;
      default = "end0";
      description = "Name of the external / WAN interface used for NAT";
    };

    restrictAccess = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Expose only TCP 25565 (Minecraft) on the WAN and allow SSH only via
        the Nebula mesh. Set to false to open SSH on the WAN during initial
        provisioning; keep true in steady state.
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
