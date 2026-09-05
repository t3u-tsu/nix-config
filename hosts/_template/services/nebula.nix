_: {
  my.networking.nebula = {
    enable = true;
    # Assign the next free IP from the 10.0.0.0/24 mesh:
    #   10.0.0.1   torii-chan (Lighthouse / Relay)
    #   10.0.0.2   sando-kun
    #   10.0.0.3   kagutsuchi-sama
    #   10.0.0.4   shosoin-tan
    #   10.0.0.100 BrokenPC
    #   10.0.0.101 x1c7
    ip = "10.0.0.5";

    # Zone separation. "mgmt" allows SSH etc.; add "app" for app services
    # reachable from the mesh (see nixos/networking/nebula.nix extraInbound).
    groups = [
      "mgmt"
    ];
  };
}
