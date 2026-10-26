{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.locales;
in
{
  options.my.home.desktop.locales = {
    enable = lib.mkEnableOption "User-specific locale and input method settings";
    inputMethod = lib.mkOption {
      type = lib.types.enum [
        "fcitx5"
        "none"
      ];
      default = "fcitx5";
      description = "User-specific input method";
    };
    keyboardLayout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Keyboard layout for the input method (e.g., 'us', 'jp')";
    };
  };

  config = lib.mkIf cfg.enable {
    home.language.base = "ja_JP.UTF-8";

    # Wayland + fcitx5 wants the GTK/Qt IM modules unset to avoid warnings.
    # lib.mkForce overrides what Home Manager's own i18n module sets.
    home.sessionVariables = lib.mkIf (cfg.inputMethod == "fcitx5") {
      GTK_IM_MODULE = lib.mkForce "";
      QT_IM_MODULE = lib.mkForce "";
      XMODIFIERS = lib.mkForce "@im=fcitx";
      SDL_IM_MODULE = lib.mkForce "fcitx";
      GLFW_IM_MODULE = lib.mkForce "ibus";
    };

    # Fcitx5 profile layout reference: https://zenn.dev/mityu/articles/nixos-fcitx5-mozc
    i18n.inputMethod = lib.mkIf (cfg.inputMethod == "fcitx5") {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = [
          pkgs.fcitx5-mozc-ut
          pkgs.kdePackages.fcitx5-qt
          pkgs.fcitx5-gtk
          pkgs.kdePackages.fcitx5-configtool
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
