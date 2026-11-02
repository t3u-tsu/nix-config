_:

{
  my.networking.nebula = {
    enable = true;
    extraInbound = [
      {
        port = 22;
        group = "mgmt";
      }
    ];
  };
}
