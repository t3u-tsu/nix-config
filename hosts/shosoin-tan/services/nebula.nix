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
