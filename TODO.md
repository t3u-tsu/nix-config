# リポジトリ改善 TODO リスト

このリストは、NixOS 設定リポジトリの保守性・拡張性、および複数拠点インフラの可用性を向上させるための未完了タスク一覧です。（※完了したタスクは履歴に残さずリストから削除します）

- **ログイン画面の調整**: greetd + `tuigreet` から `noctalia-greeter`（Noctalia 標準 greeter）への移行。flake input 追加・greetd.nix 書き換え・greeter.toml 設定が必要。Noctalia/Niri 再設計時に合わせて実施する。
- **Niri キーバインドの再設定**: flake-parts 移行でリセットされたキーバインド・レイアウト・ウィンドウルールを再設定する。最低限の操作セット（Super+T 端末, Super+Q 終了 など）から始める。
- **Noctalia Shell / Niri 設定の再設計**: 設定を一度クリアし、Noctalia v5 との連携・greeter 移行・IPC 操作などを含めて丁寧に練り直す。
- **遠隔サーバー（shosoin-tan / torii-chan）のビルド負荷対策**: 評価・ビルドをメインマシン（BrokenPC）で肩代わりさせるかリモートビルドを設定し、シェル設定も軽量化してリソース飢餓（D-Busタイムアウト等）を根本から防ぐ。
- **キャッシュサーバー（Attic等）の導入**: ホスト間でのビルドキャッシュ共有の仕組みを構築。ライセンス制約のあるパッケージ用にプライベートキャッシュを運用し、サーバーのビルド負荷を下げる。
- **comin から deploy-rs（またはキャッシュ経由プル）へのデプロイ戦略再考**: comin（プル型）のネットワーク切断への強さを残しつつ、遠隔サーバーに重いビルドをさせない最適なデプロイ手法を確定させる。
- **WireGuard から Nebula へのメッシュVPN完全移行**: 現在のネットワーク構築をフルメッシュ化し、中央の特定ホストがダウンしても生き残ったサーバー間の通信が維持されるようにする。
- **torii-chan 設定の汎用化**: torii-chan の設定を汎用化し、他のホスト(VPS等)でも使い回せるようにする。
- **フェイルオーバーVPSの導入**: torii-chan との接続が切れた場合に、Vultr などの従量課金制の格安VPSのAPIを利用し、CNAMEで動的に接続先を切り替える仕組みを導入する。
- **オニオンルーティング（Tor）による ssh バックドアの導入**: グローバルIPやVPNが全滅して torii-chan 等がダウンした際、最終手段として遠隔から ssh 接続できる裏ルートを確保する。
- **BrokenPC バックアップサーバーの構築**: BrokenPC のデータを自動で安全にバックアップ（shosoin-tan等へ退避）する仕組みを構築する。
- **GPUリソースを活用したローカルLLMサーバーのホスト**: kagutsuchi-sama や shosoin-tan の余剰GPUでローカルLLMサーバーをホストし、API等で利用できるようにする。
- **torii-chan への HE Tunnel Broker 導入**: 非力な SBC である torii-chan に Hurricane Electric Tunnel Broker を導入し、固定 IPv6 トンネルを確保してネットワーク環境を拡張・強化する。
