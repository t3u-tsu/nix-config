{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./audio.nix
    ./nebula.nix
  ];
}
