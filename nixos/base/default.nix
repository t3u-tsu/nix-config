{ ... }:
{
  imports = [
    ./user.nix
    ./nix.nix
    ./time.nix
  ];

  # Common system-wide settings shared by all hosts
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";
}
