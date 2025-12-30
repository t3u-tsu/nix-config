{ config, pkgs, ... }:

{
  services.minecraft-servers.servers.lobby = {
    enable = true;
    package = pkgs.paperServers.paper; # 常にその時点の最新安定版を指す属性

    jvmOpts = "-Xms2G -Xmx4G";

    serverProperties = {
      server-port = 25566;
      online-mode = false; # Velocity が認証を行うため false
      white-list = false;
    };

    symlinks = {
      "plugins/ViaVersion.jar" = pkgs.fetchurl {
        url = "https://github.com/ViaVersion/ViaVersion/releases/download/5.2.1/ViaVersion-5.2.1.jar";
        sha256 = "sha256-Kx83C9gb5gVd0ebM5GkmvYUrI15kSNZr2myV+6yWKsM=";
      };
      "plugins/ViaBackwards.jar" = pkgs.fetchurl {
        url = "https://github.com/ViaVersion/ViaBackwards/releases/download/5.2.1/ViaBackwards-5.2.1.jar";
        sha256 = "sha256-2wbj6CvMu8hnL260XLf8hqhr6GG/wxh+SU8uX5+x8NY=";
      };
      "velocity-forwarding.secret" = config.sops.secrets.minecraft_forwarding_secret.path;
    };

    files = {
      "config/paper-global.yml".value = {
        proxies = {
          velocity = {
            enabled = true;
            online-mode = true;
            secret = "SECRET_HERE";
          };
        };
      };
    };
  };

  # nix-minecraft が生成するサービスを拡張
  systemd.services.minecraft-server-lobby = {
    preStart = ''
      # ディレクトリの準備
      mkdir -p config
      
      # sops の秘密鍵を読み込む
      SECRET=$(cat ${config.sops.secrets.minecraft_forwarding_secret.path})
      
      # 設定ファイルがまだ存在しない場合、nix-minecraft の files 属性によって
      # 生成されるはずのパスから強制的に持ってくるか、
      # あるいは単純に sed で置換を試みる前にファイルの存在を確認します。
      if [ -f "config/paper-global.yml" ]; then
        # 書き込み権限がない場合があるため、一旦コピーして置換
        sed -i "s/secret: SECRET_HERE/secret: $SECRET/" config/paper-global.yml
      fi
    '';
  };
}
