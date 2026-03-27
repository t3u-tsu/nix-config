# 作業ログ - Index

このディレクトリには、開発セッションの記録が保存されています。

## 📅 セッション一覧

### 2026-03-27: デスクトップ最適化 Phase 1
**ファイル**: [2026-03-27-desktop-optimization.md](./2026-03-27-desktop-optimization.md)

**内容**:
- Noctalia UI 改善（bar 固定、launcher 900px）
- キーバインド統一
- Vesktop 幅調整
- Matugen インフラ構築

**成果**:
- ✅ flake check 合格
- ✅ switch 成功
- ✅ 基本的な UX 改善完了

**次のフェーズ**:
- PHASE A: Noctalia 依存度削減、Browser 拡張機能精選
- PHASE B: ドキュメント化、キーバインド整理
- PHASE C: 性能最適化

---

## 📝 使い方

新しいセッションを追加する場合：

1. `YYYY-MM-DD-topic.md` の形式でファイルを作成
2. このファイルの「セッション一覧」に追記
3. 内容には以下を含める：
   - 何をしたのか
   - 意思決定・変更内容
   - 成果・結果
   - 次のステップ

4. Git に commit：
   ```bash
   git add .agents/work-logs/
   git commit -m "docs: add session log for YYYY-MM-DD-topic"
   ```

---

## 🔗 関連ファイル

- **AGENTS.md**: 運用ルール＆開発ワークフロー（このログへのリンク含む）
- **TODO.md**: Global TODO リスト
- **README.md**: プロジェクト概要
