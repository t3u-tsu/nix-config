# hosts/shosoin-tan/services/nebula.nix
#
# Nebula mesh client (management + app). Runs the Minecraft proxy, so it accepts
# SSH from the mgmt group and Minecraft from the gateway (torii-chan, 10.0.0.1)
# for the DNAT return path.
_:

{
  my.networking.nebula = {
    enable = true;
    ip = "10.0.0.4";
    groups = [
      "mgmt"
      "app"
    ];
    extraInbound = [
      {
        port = 22;
        group = "mgmt";
      }
      # Minecraft received from the gateway (DNAT forward / return path).
      {
        port = 25565;
        host = "10.0.0.1";
      }
    ];
  };
}
