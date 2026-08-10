# hosts/sando-kun/services/nebula.nix
#
# Nebula mesh client (management). SSH via the mesh.
_:

{
  my.networking.nebula = {
    enable = true;
    ip = "10.0.0.2";
    groups = [ "mgmt" ];
    extraInbound = [
      {
        port = 22;
        group = "mgmt";
      }
    ];
  };
}
