{ config, lib, ... }:
{
  imports = [
    ./boot.nix
    ./security.nix
    ./ssh.nix
    ./user.nix
  ];
}
