{ lib, ... }:

{
  i18n.inputMethod.enable = lib.mkForce false;
  environment.sessionVariables = {
    GTK_IM_MODULE = lib.mkForce null;
    QT_IM_MODULE = lib.mkForce null;
    XMODIFIERS = lib.mkForce "@im=fcitx";
    SDL_IM_MODULE = lib.mkForce "fcitx";
    GLFW_IM_MODULE = lib.mkForce "ibus";
  };
}
