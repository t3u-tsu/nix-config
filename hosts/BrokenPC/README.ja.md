# ホスト: BrokenPC (Victus by HP 16-e1xxx)

ハイブリッドGPU構成を持つNixOSデスクトップマシン。日常業務と開発に使用されるHP Victus 16ゲーミングノートPC。

## ハードウェア仕様
- **CPU**: AMD Ryzen 7 6800H (16スレッド)
- **GPU**: 
  - NVIDIA GeForce RTX 3050 Ti Mobile (独立GPU)
  - AMD Radeon 680M (内蔵GPU)
- **RAM**: 16GB DDR5
- **ストレージ**: 512GB NVMe SSD (`nvme-MTFDKBA512TFH-1BC1AABHA_UMDMC01ZRH9LRX`)

## 🚀 インストールガイド (クリーンインストール)

NVIDIA GPUとハイブリッドグラフィックスの特性を考慮し、以下の手順でインストールを行ってください。

### フェーズ 1: ディスクの準備
1. **NixOSインストーラUSBから起動。**
2. **ネットワーク設定:** Wi-Fiまたは有線LANに接続。
3. **Diskoの実行:** 
   ```bash
   nix build .#nixosConfigurations.BrokenPC.config.system.build.diskoScript
   sudo ./result --mode zap_create_mount
   ```

### フェーズ 2: システムインストール
```bash
sudo NIXPKGS_ALLOW_UNFREE=1 nixos-install --flake .#BrokenPC
```

### フェーズ 3: 秘密鍵の転送 (重要)
秘密情報（Sops）を復号化するため、ageキーを配置します。これを行わないと、ユーザーパスワードのハッシュ値が復号できず、ログイン不能になる可能性があります。
```bash
sudo mkdir -p /mnt/var/lib/sops-nix
# /mnt/var/lib/sops-nix/key.txt に秘密鍵をコピーしてください
# 例: sudo cp /path/to/your/key.txt /mnt/var/lib/sops-nix/key.txt
```
