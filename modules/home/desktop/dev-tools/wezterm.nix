{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.home.desktop.dev-tools;
in {
  options.my.home.desktop.dev-tools.wezterm = {
    enable = mkEnableOption "WezTerm terminal emulator";
  };

  config = mkIf cfg.wezterm.enable {
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = ''
        local wezterm = require 'wezterm'
        local config = wezterm.config_builder()

        -- Font settings
        config.font = wezterm.font("Noto Sans Mono CJK JP")
        config.font_size = 12.0
        
        -- Window settings
        config.enable_wayland = true
        config.hide_tab_bar_if_only_one_tab = true
        config.window_background_opacity = 0.95

        -- Dynamic color synchronization with Noctalia (Matugen)
        local matugen_colors_path = "${config.home.homeDirectory}/.cache/noctalia/wezterm-colors.lua"
        local file = io.open(matugen_colors_path, "r")
        if file then
          file:close()
          config.colors = dofile(matugen_colors_path)
        end

        return config
      '';
    };
  };
}
