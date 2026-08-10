{ ... }:

{
  imports = [
    ./nebula.nix
    ./wireguard.nix
    ../../../nixos/services/backup/receiver.nix
  ];
}
