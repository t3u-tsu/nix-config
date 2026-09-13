# Intel SOF HDA (ThinkPad X1 Carbon 7th) ALSA UCM profile fix.
#
# The stock UCM exposes two HiFi profiles that both contain the HDMI outputs:
#   "HDMI1, HDMI2, HDMI3, Headphones, Mic1, Mic2"   (priority 10300)
#   "HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker"      (priority 10200)
# Plugging HDMI makes the HDMI port available, which also makes the Headphones
# profile available; as it outranks the Speaker profile, PipeWire selects it
# and the internal Speaker sink disappears entirely, so the built-in speakers
# can no longer be chosen.
#
# Making HDMI and Headphones mutually exclusive keeps the Headphones profile
# unavailable while only HDMI is plugged in. With the priority ordering below
# this gives:
#   jack plugged -> Headphones
#   HDMI plugged -> HDMI1 + Speaker (Speaker stays the default sink)
# HDMI2/HDMI3 have no physical connector on this model; they are demoted so
# that they can never outrank the Headphones profile.
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
  systemd.user.services.pipewire.environment.ALSA_CONFIG_UCM2 = "${alsaUcmConf}/share/alsa/ucm2";
}
