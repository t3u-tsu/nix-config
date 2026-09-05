_:

{
  my.networking.nebula = {
    enable = true;
    # Next free IP in the 10.0.0.0/24 mesh (0.1-0.4 used, 0.100 BrokenPC).
    ip = "10.0.0.5";

    # Zone separation. "mgmt" allows SSH etc.; add "app" for app services
    # reachable from the mesh (see nixos/networking/nebula.nix extraInbound).
    groups = [
      "mgmt"
    ];

    # Allow SSH from the mgmt group (needed for remote nixos-rebuild).
    extraInbound = [
      {
        port = 22;
        group = "mgmt";
      }
    ];
  };
}
