{ config, pkgs, lib, ... }:

{
  services.minecraft-servers.servers.velocity = {
    enable = true;
    package = pkgs.velocity-server;

    # Velocity は JVM 上で動くため、メモリ設定など
    jvmOpts = "-Xms512M -Xmx512M";

    # Velocity の設定ファイル (velocity.toml) の内容を宣言的に記述
    # nix-minecraft は files 属性で設定ファイルを配置できる
    files = {
      "velocity.toml".value = {
        config-version = "1.0";
        bind = "0.0.0.0:25565";
        motd = "Welcome to My NixOS Minecraft Network";
        show-max-players = 500;
        online-mode = true;
        force-key-authentication = true;
        player-info-forwarding-mode = "modern";
        forwarding-secret-file = "forwarding.secret"; # 後で生成

        servers = {
          lobby = "127.0.0.1:25566";
        };

        forced-hosts = {
          "torii-chan.t3u.uk" = [ "lobby" ];
        };

        try = [ "lobby" ];
      };
    };

    # 秘密鍵 (forwarding.secret) を symlink する設定
    # 実際には sops などで管理するか、初回起動時に生成させる
    symlinks = {
      "forwarding.secret" = config.sops.secrets.minecraft_forwarding_secret.path;
    };
  };
}
