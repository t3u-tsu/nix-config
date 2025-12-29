{ pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  # SDイメージの圧縮を無効化（ビルド時間短縮 & すぐ焼けるように）
  sdImage.compressImage = false;

  # Orange Pi Zero 3 向け U-Boot 書き込み処理
  # nixpkgsにubootOrangePiZero3が含まれているか、Overlayで追加されている前提
  sdImage.postBuildCommands = ''
    echo "Writing U-Boot to image..."
    dd if=${pkgs.ubootOrangePiZero3}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
  '';

  # 初回起動時はSOPS鍵がなくパスワードハッシュが読み込めないため、
  # sudoをパスワードなしで実行できるようにする（ロックアウト回避）。
  security.sudo.wheelNeedsPassword = lib.mkForce false;
}
