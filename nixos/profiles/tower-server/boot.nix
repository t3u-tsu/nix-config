{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages;

  nixpkgs.config.allowUnfree = true;
}
