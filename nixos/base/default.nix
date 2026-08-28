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

  # Silence the nixpkgs warning (default flips to false in 26.11); no host uses ZFS pools.
  boot.zfs.forceImportRoot = false;
}
