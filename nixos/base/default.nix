{ ... }:
{
  imports = [
    ./user.nix
    ./nix.nix
    ./time.nix
  ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";

  # Silence the nixpkgs warning that this option's default changes in 26.11.
  boot.zfs.forceImportRoot = false;
}
