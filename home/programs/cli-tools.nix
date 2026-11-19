{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    bat = {
      enable = true;
      config = {
        pager = "less -FR";
      };
      extraPackages = with pkgs.bat-extras; [
        batman
        batdiff
      ];
    };

    eza = {
      enable = true;
      enableZshIntegration = true;
      icons = "auto";
      colors = "auto";
      git = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f --strip-cwd-prefix --hidden --exclude .git";
      fileWidgetCommand = "fd --type f --strip-cwd-prefix --hidden --exclude .git";
      changeDirWidgetCommand = "fd --type d --strip-cwd-prefix --hidden --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
      ];
    };

    zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
    };

    fd.enable = true;
    ripgrep.enable = true;

    yazi = {
      enable = true;
      enableZshIntegration = true;
    };

    tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
      stdlib = ''
        _nix_direnv_warn_manual_reload() {
          local profile_rc=$1
          local layout_dir
          layout_dir=$(direnv_layout_dir)
          local reload_bin="''${layout_dir}/bin/nix-direnv-reload"

          if [[ -e $profile_rc && -x $reload_bin ]]; then
            if command -v systemd-run >/dev/null 2>&1; then
              local unit
              unit="nix-direnv-reload-$(systemd-escape -p "$PWD")"
              systemctl --user reset-failed "$unit" 2>/dev/null || true
              _nix_direnv_warning "cache is out of date; reloading in background (unit: $unit)..."
              systemd-run --user --quiet --unit="$unit" --description="nix-direnv reload" bash -c '
                if "$1"; then
                  if command -v notify-send >/dev/null 2>&1; then
                    notify-send -u normal "nix-direnv" "reload finished: $3"
                  fi
                else
                  status=$?
                  if command -v notify-send >/dev/null 2>&1; then
                    notify-send -u critical "nix-direnv" "reload failed: $3 (journalctl --user -u $2)"
                  fi
                  exit "$status"
                fi
              ' nix-direnv-reload "$reload_bin" "$unit" "$PWD"
            else
              _nix_direnv_warning 'cache is out of date; reloading in foreground...'
              _nix_direnv_force_reload=1
            fi
          else
            _nix_direnv_warning 'cache does not exist. creating in foreground...'
            _nix_direnv_force_reload=1
          fi
        }

        nix_direnv_manual_reload
      '';
    };
  };

  home = {
    sessionVariables = {
      EDITOR = lib.mkDefault "vim";
      VISUAL = lib.mkDefault "vim";
    };
    shellAliases = {
      da = "direnv allow";
      ndr = "nix-direnv-reload";
      ndr-ps = "systemctl --user list-units 'nix-direnv-reload-*' --all --no-pager";
      ndr-log = "journalctl --user -u 'nix-direnv-reload-*' -f -n 50";
    };
  };
}
