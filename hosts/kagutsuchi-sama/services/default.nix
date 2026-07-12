{ ... }:

{
  imports = [
    ./wireguard.nix
    ../../../nixos/services/backup/receiver.nix
  ];
}
