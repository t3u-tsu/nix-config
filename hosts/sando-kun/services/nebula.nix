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
