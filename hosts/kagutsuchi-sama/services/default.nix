{ ... }:

{
  imports = [
    ./wireguard.nix
    ../../../services/backup/receiver.nix
  ];
}
