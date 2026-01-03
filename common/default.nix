{ pkgs, ... }:

{
  imports = [
    ./nix.nix
    ./auto-update.nix
    ./local-network.nix
    ./time.nix
    ./backup-restic.nix
  ];

  environment.systemPackages = with pkgs; [
    vim
    git
    tmux
    htop
    rsync
    pciutils
    usbutils
    wget
    curl
    dnsutils # dig 等
  ];
}
