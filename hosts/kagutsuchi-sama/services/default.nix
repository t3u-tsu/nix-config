{ ... }:

{
  imports = [
    ./emergency-ssh.nix
    ./nebula.nix
  ];

  my.services.backup.receiver.enable = true;
}
