{ lib, config, ... }:

with lib;
let
  cfg = config.my.services.desktop.pipewire;
in
{
  options.my.services.desktop.pipewire = {
    enable = mkEnableOption "PipeWire audio base";
  };

  config = mkIf cfg.enable {
    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
