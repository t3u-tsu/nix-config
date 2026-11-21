{
  lib,
  pkgs,
  ...
}:

let
  nixDirenvReload = pkgs.writeYshApplication {
    name = "nix-direnv-bg-reload";
    runtimeInputs = [
      pkgs.libnotify
      pkgs.systemd
    ];
    text = builtins.readFile ./nix-direnv-reload.ysh;
  };
in
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
    stdlib = ''
      _nix_direnv_warn_manual_reload() {
        local layout_dir
        layout_dir=$(direnv_layout_dir)
        ${lib.getExe nixDirenvReload} "$1" "''${layout_dir}/bin/nix-direnv-reload" "$PWD"
      }

      nix_direnv_manual_reload
    '';
  };

  home.shellAliases = {
    da = "direnv allow";
    ndr-ps = "systemctl --user list-units 'nix-direnv-reload-*' --all --no-pager";
    ndr-log = "journalctl --user -u 'nix-direnv-reload-*' -f -n 50";
  };
}
