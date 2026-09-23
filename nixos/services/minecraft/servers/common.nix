# Shared helpers for the Paper backend servers.
{ pkgs, lib }:

let
  plugins = pkgs.callPackage ../../../../_sources/generated.nix { };
  lunachat = import ../plugins/lunachat.nix { };

  # Fix the udev warning printed by the Paper server.
  ldLibraryPath = lib.makeLibraryPath [ pkgs.udev ];
in
{
  inherit plugins lunachat ldLibraryPath;

  # secretPath: path to the shared Velocity forwarding secret.
  mkPaperGlobalPreStart = { secretPath }: ''
    mkdir -p config
    SECRET=$(cat ${secretPath})

    # If the config file is a symlink into the Nix store (or similar), it cannot
    # be rewritten, so remove/move it aside and place a real file instead
    if [ -L "config/paper-global.yml" ]; then
      rm "config/paper-global.yml"
    fi

    cat <<EOF > config/paper-global.yml
    # Fix global config version warning
    config-version: 31
    proxies:
      velocity:
        enabled: true
        online-mode: true
        secret: $SECRET
    EOF
    chown minecraft:minecraft config/paper-global.yml
    chmod 600 config/paper-global.yml
  '';
}
