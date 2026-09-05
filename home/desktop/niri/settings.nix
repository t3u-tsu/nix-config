# Niri configuration.
#
# The whole configuration is managed as a raw KDL file (./config.kdl) because
# niri-flake's typed `programs.niri.settings` does not cover niri v26.04
# features such as `blur` / `background-effect`. `programs.niri.config`
# completely replaces `settings`, so the typed attrset must not be set.
{
  programs.niri.config = builtins.readFile ./config.kdl;
}
