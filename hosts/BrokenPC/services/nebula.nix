# hosts/BrokenPC/services/nebula.nix
#
# Nebula mesh client (management + app). No services -> ICMP only (common module).
_:

{
  my.networking.nebula = {
    enable = true;
    ip = "10.0.0.100";
    groups = [
      "mgmt"
      "app"
    ];
  };
}
