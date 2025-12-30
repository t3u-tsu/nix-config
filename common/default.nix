{ pkgs, ... }:

{
  imports = [
    ./auto-update.nix
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
