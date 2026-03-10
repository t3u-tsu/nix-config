{ ... }: {
  imports = [
    ./user.nix
    ./nix.nix
    ./time.nix
    ./i18n.nix
    ./networking.nix
    ./wireguard.nix
    ./sops.nix
    ../services/update-hub
  ];
}
