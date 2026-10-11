{ ... }:

{
  imports = [
    ./nebula.nix
  ];

  my.services.backup.receiver.enable = true;
}
