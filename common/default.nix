{ pkgs, ... }:

{
  imports = [
    ./auto-update.nix
    ./local-network.nix
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
