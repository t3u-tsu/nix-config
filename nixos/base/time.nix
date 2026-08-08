{ pkgs, ... }:

{
  time.timeZone = "Asia/Tokyo";

  services.chrony.enable = true;
}
