# 作業ログ: BrokenPC IOMMU・NVIDIA設定の最適化

**日付**: 2026-05-02
**作業ブランチ**: main (直接作業)
**対象ホスト**: BrokenPC (HP Victus 16-e1065ax / Ryzen 7 6800H + RTX 3050 Ti)

## 概要
BrokenPC において以下のハードウェア起因の不安定な挙動が報告されたため、調査と対策を実施した。
1. 起動時に一時的に音声が乱れる
2. NVIDIA GPU に負荷をかけるとクラッシュする
3. I2C タッチパッドが反応しなくなる

これらは AMD プラットフォームにおける IOMMU の DMA 変換処理の遅延やバグ（ACPI の不備に起因）による典型的な問題であるため、回避策としてカーネルパラメータに `iommu=pt` と `amd_iommu=on` を追加した。また、NVIDIA の PRIME Offload モードを無効化し、Sync モードで安定動作させる設定へと切り替えた。

## 変更内容
1. `modules/hardware/nvidia.nix`: 
   - `prime.sync.enable` および `prime.offload.enable` のオプションを定義し、Offload モードと Sync モードを個別に制御できるようにリファクタリング。
2. `hosts/BrokenPC/configuration.nix`:
   - `boot.kernelParams` に `[ "amd_iommu=on" "iommu=pt" ]` を追加。
   - `my.hardware.nvidia.prime.offload.enable = false;` および `sync.enable = true;` を設定。

## 留意事項
- `sudo` によるビルド適用はエージェントから直接行えなかったため、ユーザー側に実機での `sudo nixos-rebuild switch --flake .#BrokenPC` と再起動後の動作確認を依頼中。
- 再起動後、`dmesg | grep -i iommu` にて Pass-Through モードになっていることを確認する必要がある。
