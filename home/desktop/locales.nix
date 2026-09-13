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

    # Wayland + fcitx5 wants the GTK/Qt IM modules unset to avoid warnings.
    # mkForce overrides what Home Manager's own i18n module sets.
    home.sessionVariables = {
      GTK_IM_MODULE = mkForce "";
      QT_IM_MODULE = mkForce "";
      XMODIFIERS = mkForce "@im=fcitx";
      SDL_IM_MODULE = mkForce "fcitx";
      GLFW_IM_MODULE = mkForce "ibus";
    };

    # Fcitx5 profile layout reference: https://zenn.dev/mityu/articles/nixos-fcitx5-mozc
    i18n.inputMethod = mkIf (cfg.inputMethod == "fcitx5") {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          fcitx5-mozc-ut
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
