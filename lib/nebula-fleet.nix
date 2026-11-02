# Single source of truth for Nebula mesh VPN nodes and network configuration.
let
  prefix = "10.0.0";
  mkNode = octet: groups: {
    inherit octet groups;
    ip = "${prefix}.${toString octet}";
  };
  nodes = {
    torii-chan = mkNode 1 [ "mgmt" ];
    sando-kun = mkNode 2 [ "mgmt" ];
    kagutsuchi-sama = mkNode 3 [ "mgmt" ];
    shosoin-tan = mkNode 4 [
      "mgmt"
      "app"
    ];
    BrokenPC = mkNode 100 [
      "mgmt"
      "app"
    ];
    x1c7 = mkNode 101 [
      "mgmt"
      "app"
    ];
  };
in
{
  inherit prefix nodes;
  subnet = "${prefix}.0/24";
  fleet = builtins.attrValues (builtins.mapAttrs (name: info: info // { inherit name; }) nodes);
}
