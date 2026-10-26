{ lib, config, ... }:

let
  cfg = config.my.services.desktop.pipewire;
in
{
  options.my.services.desktop.pipewire = {
    enable = lib.mkEnableOption "PipeWire audio base";
  };

  config = lib.mkIf cfg.enable {
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
