{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.chromium;
in
{
  options.my.services.desktop.chromium = {
    enable = mkEnableOption "Chromium system-managed policies (default-browser, sync)";
  };

  config = mkIf cfg.enable {
    # Linux Chromium reads managed policies only from a root-owned
    # /etc/chromium/policies/managed; a user-level ~/.config path is not a
    # managed location (a user could overwrite it), so keep it system-scoped.
    environment.etc."chromium/policies/managed/noctalia.json".text = builtins.toJSON {
      DefaultBrowserSettingEnabled = false;
      BrowserSignin = 0;
      SyncDisabled = true;
    };
  };
}
