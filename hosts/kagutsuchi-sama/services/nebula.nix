_:

{
  my.networking.nebula = {
    enable = true;
    ip = "10.0.0.3";
    groups = [ "mgmt" ];
    extraInbound = [
      {
        port = 22;
        group = "mgmt";
      }
    ];
  };
}
