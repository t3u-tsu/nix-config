{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.locales;
in
{
  options.my.home.desktop.locales = {
    enable = mkEnableOption "User-specific locale and input method settings";
    inputMethod = mkOption {
      type = types.enum [
        "fcitx5"
        "none"
      ];
      default = "fcitx5";
      description = "User-specific input method";
    };
    keyboardLayout = mkOption {
      type = types.str;
      default = "us";
      description = "Keyboard layout for the input method (e.g., 'us', 'jp')";
    };
  };

  config = mkIf cfg.enable {
    home.language.base = "ja_JP.UTF-8";

    # Force unset IM modules in Wayland session to avoid warnings
    # Use mkForce to override the default settings from Home Manager's i18n module
    home.sessionVariables = {
      GTK_IM_MODULE = mkForce "";
      QT_IM_MODULE = mkForce "";
      XMODIFIERS = mkForce "@im=fcitx";
      SDL_IM_MODULE = mkForce "fcitx";
      GLFW_IM_MODULE = mkForce "ibus";
    };

    # Fcitx5 user profile settings (declaratively enable Mozc)
    # Reference: https://zenn.dev/mityu/articles/nixos-fcitx5-mozc
    # Disable the system-wide i18n.inputMethod and manage everything here
    i18n.inputMethod = mkIf (cfg.inputMethod == "fcitx5") {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          fcitx5-mozc
          kdePackages.fcitx5-qt
          fcitx5-gtk
          kdePackages.fcitx5-configtool
        ];
        settings.inputMethod = {
          GroupOrder = {
            "0" = "Default";
          };
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = cfg.keyboardLayout;
            DefaultIM = "mozc";
          };
          "Groups/0/Items/0" = {
            Name = "keyboard-${cfg.keyboardLayout}";
          };
          "Groups/0/Items/1" = {
            Name = "mozc";
          };
        };
      };
    };
  };
}
