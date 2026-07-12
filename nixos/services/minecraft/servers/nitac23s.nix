{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.services.minecraft;
  # 自動生成されたプラグイン情報を読み込む
  plugins = pkgs.callPackage ../plugins/generated.nix { };
  lunachat = import ../plugins/lunachat.nix { };

  # server.properties のベース設定 (パスワード抜き)
  serverProperties = {
    server-port = 25567;
    max-players = 30;
    online-mode = false;
    white-list = true;
    allow-flight = true;
    difficulty = "hard";
    gamemode = "survival";
    enable-command-block = true;
    generate-structures = true;
    view-distance = 12;
    enable-rcon = true;
    "rcon.port" = 25575;
  };

  staticProps = lib.generators.toKeyValue {
    mkKeyValue = lib.generators.mkKeyValueDefault { } "=";
  } serverProperties;
in
{
  config = mkIf cfg.enable {
    services.minecraft-servers.servers.nitac23s = {
      enable = true;
      package = pkgs.paperServers.paper;

      jvmOpts = "-Xms4G -Xmx8G";

      # We manage server.properties manually in preStart
      serverProperties = { };

      symlinks = {
        "plugins/ViaVersion.jar" = plugins.viaversion.src;
        "plugins/ViaBackwards.jar" = plugins.viabackwards.src;
        "plugins/GSit.jar" = plugins.gsit.src;
        "plugins/LunaChat.jar" = plugins.lunachat.src;
      };

      files = {
        # 共通設定から LunaChat の設定を引用
        "plugins/LunaChat/config.yml".value = lunachat.config.lunaChatConfig;
      };
    };

    systemd.services.minecraft-server-nitac23s = {
      # Fix udev warning
      environment.LD_LIBRARY_PATH = "${lib.makeLibraryPath [ pkgs.udev ]}";

      preStart = lib.mkAfter ''
              # 1. RCON Password 取得
              RCON_PASS=$(cat ${config.sops.secrets.nitac23s_rcon_password.path})

              # 2. server.properties を新規作成 (上書き)
              # 既存のリンクがある場合は削除
              if [ -L server.properties ]; then rm server.properties; fi
              
              cat <<EOF > server.properties
        ${staticProps}
        rcon.password=$RCON_PASS
        EOF
              chown minecraft:minecraft server.properties
              chmod 600 server.properties

              # 3. paper-global.yml の生成
              mkdir -p config
              SECRET=$(cat ${config.sops.secrets.minecraft_forwarding_secret.path})
              if [ -L "config/paper-global.yml" ]; then rm "config/paper-global.yml"; fi
              
              cat <<EOF > config/paper-global.yml
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
    };
  };
}
