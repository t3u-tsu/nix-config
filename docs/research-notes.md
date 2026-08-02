# 調査メモ - ConoHa VPS（512MB）向けカスタム NixOS インストーラ ISO

`nixos/installer/` の設計にあたって実施した調査のメモ。
参照元は各項目末尾のリンク（nixpkgs のコードはすべて `nixos-26.05` ブランチ）。

## 1. nixos-generators は NixOS 25.05 以降非推奨

- リポジトリ: https://github.com/nix-community/nixos-generators
- README 冒頭に「deprecated: nixos-generators / Starting with NixOS 25.05, most of
  nixos-generators has been upstreamed into nixpkgs」と明記。
- 移行先は `nixos-rebuild build-image` コマンドと、flake 上では
  `config.system.build.images.<variant>` 属性。
- 旧 nixos-generators のフォーマットとの対応（README の表より）:
  - `install-iso` → nixpkgs の `iso-installer` バリアント
  - `iso` → `iso` バリアント
  - `openstack` / `qcow` 等は `system.build.images` にも存在

### nixos-generators の旧フォーマット定義（参考）

`formats/iso.nix`:

```nix
{
  modulesPath, ...
}: {
  imports = [ "${toString modulesPath}/installer/cd-dvd/iso-image.nix" ];
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  formatAttr = "isoImage";
  fileExtension = ".iso";
}
```

`formats/install-iso.nix`:

```nix
{
  lib, modulesPath, ...
}: {
  imports = [ "${toString modulesPath}/installer/cd-dvd/installation-cd-base.nix" ];
  # 起動時に sshd / wpa_supplicant を確実に立ち上げる
  systemd.services.wpa_supplicant.wantedBy = lib.mkForce ["multi-user.target"];
  systemd.services.sshd.wantedBy = lib.mkForce ["multi-user.target"];
  formatAttr = "isoImage";
  fileExtension = ".iso";
}
```

※ 本リポジトリは nixos-26.05 のため、nixos-generators は使わず nixpkgs 標準の
image framework（後述）を採用した。

## 2. nixpkgs 標準の image framework（nixos-26.05）

- `nixos/modules/image/images.nix`（module-list.nix の 143 行目で全 NixOS 設定に自動 import）
  - `system.build.images` = バリアント名 → イメージ派生のマップ
  - `image.modules` = バリアント名 → モジュールのマップ（ユーザーが拡張・上書き可能）
  - `iso` → `nixos/modules/installer/cd-dvd/iso-image.nix`
  - `iso-installer` → `nixos/modules/installer/cd-dvd/installation-cd-base.nix`
- `nixos/modules/installer/cd-dvd/iso-image.nix`
  - `config.system.build.isoImage` と `config.system.build.image` を定義（1038 行目）
  - `image.baseName` 等は `nixos/modules/image/file-options.nix` を import して定義（555 行目）
  - ライブ環境のファイルシステム: `/` は tmpfs、`/iso` は iso9660、
    `/nix/store` は squashfs(ro) + tmpfs(rw) のオーバーレイ ← **メモリ制約の要**
  - 主なオプション: `isoImage.compressImage` / `squashfsCompression` / `edition` /
    `volumeID` / `contents` / `storeContents` / `includeSystemBuildDependencies` /
    `makeBiosBootable` / `makeEfiBootable` / `makeUsbBootable` /
    `prependToMenuLabel` / `appendToMenuLabel` / `forceTextMode` など
- `nixos/modules/installer/cd-dvd/installation-cd-base.nix`
  - `iso-image.nix` + `profiles/base.nix` + `profiles/installation-device.nix` を import
  - `hardware.enableAllHardware = true`、EFI/USB ブート有効、`nixos` ユーザー自動ログイン等
- ビルド方法（nixpkgs 公式マニュアル
  `nixos/doc/manual/installation/building-images-via-nixos-rebuild-build-image.chapter.md`）:
  - `nixos-rebuild build-image --image-variant <name>`
  - バリアント毎のカスタマイズは `image.modules.<variant> = { ... };` で行う

## 3. 標準インストーラ ISO の SSH（誤解の訂正）

「標準 minimal ISO は SSH が無効」とされがちだが、**実際は sshd は有効**である
（`nixos/modules/profiles/installation-device.nix`）:

```nix
services.openssh = {
  enable = mkDefault true;
  settings.PermitRootLogin = mkDefault "yes";
};
```

ただしログインできるのは「コンソールで `passwd` を設定した後」または
「authorized_keys を手動追加した後」のみ（getty のヘルプテキストにも明記）。
またネットワークは NetworkManager（DHCP 前提）であり、**ConoHa は DHCP を提供しない**。

→ したがって「SSH で即ログインできる + 静的 IP」を実現するにはカスタム ISO が必須。
本実装では `services.openssh.enable = true` + `users.users.root.openssh.authorizedKeys.keys`
+ 静的 IP 設定 + `networking.networkmanager.enable = mkForce false` を行った。

## 4. 512MB RAM での起動・インストールの実現性

### 起動

- minimal インストーラ ISO は 512MB で起動可能（実績多数）。
  initrd（systemd stage-1）+ tmpfs ルート + squashfs ストアで合計 200〜300MB 程度。
- ヘッドレス環境では VNC に文字が出ないことがあるため
  `console=tty0 console=ttyS0,115200n8 nomodeset` をカーネルパラメータに追加
  （Proxmox 上の 512MB VM で同様の事例: yashgarg.dev "Running NixOS on Low-Memory Servers"）。

### nixos-install

- ライブ環境の `/nix/store` は tmpfs オーバーレイのため、**キャッシュからの
  ダウンロード展開が RAM を消費する**。512MB では OOM しうる。
- 対策（本実装）:
  1. zram（圧縮スワップ、memoryPercent=50）+ `vm.swappiness=100`
  2. `install-nixos.sh install` がターゲットディスクに swap ファイル（1G）を作成して
     ライブ環境で `swapon`（インストール中のみの一時 swap）
  3. （任意・推奨）`isoImage.storeContents` にターゲットの `system.build.toplevel` を
     入れておくと、nixos-install はストア内クロージャをコピーするだけで
     ネットワーク不要になり、確実に 512MB で完走する
- nixos-install の仕組み: ローカルストア（ISO の squashfs ストア）から
  クロージャをコピーし、不足分は substituter（cache.nixos.org）から取得する。
  `--no-root-passwd` で root パスワード未設定（鍵ログインのみ）にできる。

### nixos-anywhere が 512MB で不可の理由

- nixos-anywhere はターゲット上で kexec した NixOS を起動して nix-daemon を動かし、
  そこにクロージャを転送・適用する。公式要件は 1.5GB RAM（kexec + 一時ストア + ビルド
  のための余裕）。ISO 方式はライブ環境のストアをそのまま使うため 512MB でも現実的。

## 5. ConoHa VPS 固有の注意

- **DHCP なし**: コントロールパネル / API で割り当てられた IPv4 とゲートウェイを
  静的設定する。IP は `terraform apply` 後の
  `terraform output -json torii_chan_addresses` で確定する
  （terraform/outputs.tf のコメントにも記載あり）。
- NIC は virtio。systemd の予測可能な命名を無効化（`networking.usePredictableInterfaceNames
  = false`）すれば eth0 で扱える（Debian 標準イメージと同じ名前）。
- ブートボリュームは通常 `/dev/vda`（`terraform/scripts/nixos-iso.sh` は rescue 用 ISO を
  `hw_rescue_bus: ide` の CD-ROM として注入）。
- rescue ISO の注入 → BIOS ブートのため、ISO は `makeBiosBootable`（x86 ではデフォルト true）
  が必要。EFI 不要なら `makeEfiBootable` は無効化しても良い（インストーラ base は
  デフォルトで有効化するが、BIOS のみの環境では無害）。

## 6. リポジトリ構成との関係

- ルート `flake.nix` は flake-parts ベース（`flake/hosts.nix`、`flake/overlays.nix` を import）。
  nixpkgs は `nixos-26.05` を固定（flake.lock）。
- `hosts/torii-chan` は Orange Pi Zero 3（aarch64）の既存ホストで、`vps.nix`（wanIp /
  wanGateway を持つ想定の VPS 設定）は別タスクで作成予定（terraform/README.md 参照）。
- VPS は x86_64 のため、本インストーラ ISO は `x86_64-linux` でビルドする。
- `nixos/profiles/` の `tower-server` / `sbc` は「サーバーユーザー + SSH 鍵」の既存パターン。
  本実装の `ssh.nix` はこれらと整合する書き方（`users.users.*.openssh.authorizedKeys.keys`）
  を踏襲している。

## 7. 決定事項まとめ

| 論点 | 決定 |
| :--- | :--- |
| ISO 生成 | nixpkgs 標準 `system.build.images.iso-installer`（nixos-generators は非推奨のため不使用） |
| ビルド経路 | `nixos/installer/flake.nix` のサブ flake（ルート flake.nix は変更しない）。統合時は packages に公開 |
| SSH | `services.openssh.enable` + root の authorizedKeys（t3u 公開鍵）。`PermitRootLogin = "prohibit-password"`、パスワード認証無効 |
| ネットワーク | 静的 IP。`conoha.installer.wan.*` で変数化し、`wan-ip.nix` を差し込み口に。未設定時は手動設定（`install-nixos network`）でフォールバック |
| 512MB 対策 | zram + swappiness=100 + インストール前 swap 作成（install-nixos.sh）。任意で `isoImage.storeContents` にターゲットクロージャを同梱 |
| コンソール | `console=tty0 console=ttyS0,115200n8 nomodeset` を追加 |
| インストール補助 | `install-nixos.sh`（network / install / status サブコマンド）を ISO に同梱 |
