# 日常保守 & ライフサイクル管理

本ドキュメントは，本リポジトリの継続的な保守運用，日次自動更新の仕組み，ディスク容量管理（ガベージコレクション），および安全なカーネル更新の手順を記述する．

---

## 1. 自動更新パイプライン (`auto-update.yml`)

GitHub Actions のスケジュールワークフローが毎日日本時間 04:00 に自動実行される．

1. **`nvfetcher` の実行**:
   `nvfetcher.toml` に定義された最新パッケージ（上流 GitHub リリース等）のコミット・ハッシュ値を更新し，`_sources/generated.nix` を更新する．
2. **`flake.lock` の更新**:
   依存する Flake 入力（`nixpkgs`, 各種ツール）を最新に更新する．
3. **CI 検証**:
   全ホストの評価と pre-commit hooks（`nix flake check`）を実行する．
4. **自動コミット**:
   すべての検証に成功した場合のみ，コミットを作成して `main` ブランチへ自動プッシュする．

### 手動での更新実行
ローカルでパッケージやロックファイルを先行して更新する場合:
```bash
# nvfetcher パッケージの更新
nix run .#nvfetcher

# flake inputs の更新
nix flake update

# 変更の検証
nix flake check
```

---

## 2. ディスク容量管理とガベージコレクション

NixOS ではビルド生成物や古い世代（generations）が `/nix/store` に蓄積するため，定期的なクリーンアップを行う．

### 不要世代の削除とストア掃除
```bash
# 30日以上前の古い世代を削除し，未参照の store パスを回収
nix-collect-garbage --delete-older-than 30d

# ハードリンクによる重複ブロックの最適化
nix-store --optimise
```

### 低容量マシン（SBC / ラップトップ）での緊急回収
```bash
# 現在の世代を除く全世代を一括破棄
sudo nix-collect-garbage -d
sudo /run/current-system/bin/switch-to-configuration boot
```

---

## 3. カーネル更新と再起動

Linux カーネルのバージョンが更新された場合，完全な適用には OS の再起動が必要となる．

1. **ドライランでカーネル更新の有無を確認**:
   ```bash
   sudo nixos-rebuild dry-build --flake .#<hostname>
   ```
2. **適用**:
   ```bash
   # ローカルマシン
   sudo nixos-rebuild switch --flake .#<hostname>

   # リモート機（再起動前に boot エントリを更新）
   nixos-rebuild boot --flake .#<hostname> --target-host t3u@10.0.0.X --sudo --ask-sudo-password
   ssh t3u@10.0.0.X "sudo reboot"
   ```
3. **起動失敗時のロールバック**:
   万一カーネルの非互換性で起動に失敗した場合は，ブートローダ（systemd-boot または GRUB）の選択画面で直前の世代を選択して起動する．詳細は [`../troubleshooting/emergency-recovery.md`](../troubleshooting/emergency-recovery.md) を参照．

---

## 関連ドキュメント
- [リポジトリ全体アーキテクチャ](../architecture/overview.md)
- [トラブルシューティング: ビルド・デプロイ](../troubleshooting/build-and-deploy.md)
- [トラブルシューティング: 緊急時復旧](../troubleshooting/emergency-recovery.md)
