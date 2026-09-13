# Intel SOF HDA (ThinkPad X1 Carbon 7th) ALSA UCM workaround: plugging HDMI makes
# the Headphones profile available, and it outranks the Speaker profile, so
# PipeWire drops the internal Speaker sink. HDMI and Headphones are made mutually
# exclusive so Speaker stays selectable (priorities below decide jack vs HDMI).
{ pkgs, ... }:

let
  alsaUcmConf = pkgs.alsa-ucm-conf.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
            ucm="$out/share/alsa/ucm2"

            substituteInPlace "$ucm/codecs/hda/hdmi.conf" \
              --replace-fail \
                'Comment "HDMI / DisplayPort ''${var:__Number} Output"' \
                'Comment "HDMI / DisplayPort ''${var:__Number} Output"
      			ConflictingDevice [ "Headphones" ]'

            sed -i \
              -e '/Number 1/,/Priority/s/Priority 500/Priority 700/' \
              -e '/Number 2/,/Priority/s/Priority 600/Priority 100/' \
              -e '/Number 3/,/Priority/s/Priority 700/Priority 50/' \
              "$ucm/Intel/sof-hda-dsp/Hdmi.conf"

            substituteInPlace "$ucm/HDA/HiFi-analog.conf" \
              --replace-fail 'PlaybackPriority 200' 'PlaybackPriority 900'
    '';
  });
in
{
  # Both processes open the ALSA card, so both need the overridden UCM set: with
  # PipeWire alone, WirePlumber still reads the stock UCM and the Speaker sink
  # disappears while HDMI is plugged in.
  systemd.user.services.pipewire.environment.ALSA_CONFIG_UCM2 = "${alsaUcmConf}/share/alsa/ucm2";
  systemd.user.services.wireplumber.environment.ALSA_CONFIG_UCM2 = "${alsaUcmConf}/share/alsa/ucm2";
}
