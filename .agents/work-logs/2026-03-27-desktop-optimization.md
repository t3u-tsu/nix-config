# デスクトップ最適化 - 現状と今後

## 📋 完了した作業

### ✅ Phase 1: 基本構築（完了）
- Noctalia UI 改善（bar 固定、launcher 900px）
- キーバインド統一（Mod+M, Mod+W, Mod+Space 等）
- ウィンドウルール拡張
- Matugen テンプレート定義

### ✅ 追加修正（完了）
- Vesktop 幅を 1.0 に統一

---

## 📊 現状スナップショット

### Git Status
```
commit 1d72020: fix(desktop): set Vesktop to full-width (1.0)
commit 094efec: fix(desktop): simplify Matugen config
commit d35789a: fix(desktop): launcher width 900px, fix Matugen command
commit 6c1cc80: feat(desktop): Phase 1 desktop optimization
```

### ローカル構成
- System services: 7 ファイル
- Home-manager: 22 ファイル
- Niri/Noctalia 統合: ✅
- Keybinds: ✅
- Themes: ✅ (Dracula)
- Extensions/Tools: ✅

---

## 🔍 推奨ローカル検証

### UI/UX 確認
```
Mod+Space → launcher が見やすいか？
Mod+Escape → session menu が反応するか？
Mod+Shift+V → Vesktop が画面端おかしくないか？
Print → screenshot 機能が動くか？
```

### 性能確認
```
起動直後の CPU/メモリ
Zen/Vesktop の起動時間
Noctalia の軽さ
```

### 問題報告用
- 起動エラー
- キーバインド未反応
- 重い・遅い
→ ここに詳しく報告してください

---

## 📈 今後の計画

### PHASE A: 改善（このサイクル）
**必須:**
- Noctalia 依存度削減（fallback キーバインド）
- Browser 拡張機能の精選（削除候補：Dark Reader 等）

**オプション:**
- Dev-tools 充実（Neovim LSP 設定追加）
- Service 層クリーンアップ（fcitx5 重複確認）

### PHASE B: ドキュメント化（数日後）
- Niri keybinds README 作成
- Desktop module structure 図解
- Troubleshooting guide

### PHASE C: 最適化（1-2週間後）
- Matugen 自動実行復活
- Startup profile 分離
- Performance tuning

---

## 🎯 判断ポイント

以下のいずれかが当てはまったら、PHASE A に進みます：

- ✓ キーバインドが反応しない
- ✓ 起動が遅い（> 10秒）
- ✓ Noctalia が不安定
- ✓ UI に誤表示

---

## 📝 次のアクション

1. **あなた**：ローカルで上記の確認をする
2. **問題があれば**：ここに報告
3. **問題なければ**：PHASE B に進む（ドキュメント化）
