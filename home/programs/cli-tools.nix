{
  lib,
  pkgs,
  ...
}:

let
  nixDirenvReloadNotify = pkgs.writeYshApplication {
    name = "nix-direnv-reload-notify";
    runtimeInputs = [ pkgs.libnotify ];
    text = ''
      var reload_bin = ARGV[0]
      var unit = ARGV[1]
      var workdir = ARGV[2]

      shopt --unset verbose_errexit {
        try { $reload_bin }
      }
      if failed {
        var code = _error.code
        try { notify-send -u critical -a direnv "nix-direnv" "reload failed: $workdir (journalctl --user -u $unit)" }
        exit $code
      }
      try { notify-send -u normal -a direnv "nix-direnv" "reload finished: $workdir" }
    '';
  };
in
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
        _nix_direnv_notify_tty() {
          local msg=$1
          if [[ -w /dev/tty ]]; then
            printf '\033[33m[direnv]\033[0m %s\n' "$msg" >/dev/tty
          else
            printf '[direnv] %s\n' "$msg" >&2
          fi
        }

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
              _nix_direnv_notify_tty "reloading in background (ndr-ps / ndr-log)"
              systemd-run --user --quiet --unit="$unit" --description="nix-direnv reload" \
                ${lib.getExe nixDirenvReloadNotify} "$reload_bin" "$unit" "$PWD"
            else
              _nix_direnv_notify_tty "reloading in foreground..."
              "$reload_bin"
            fi
          else
            _nix_direnv_notify_tty "cache does not exist; run 'ndr' to build"
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
