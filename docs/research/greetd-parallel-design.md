# greetd API 互換並行認証デーモン (greetd-parallel) の設計仕様

greetd の API 互換を維持しつつ，指紋とパスワードの並行待ち受けに対応したディスプレイマネージャ (`greetd-parallel`) のアーキテクチャ設計仕様と技術的実現性の検証記録．

---

## 1. 設計目標とコンセプト

- 既存の Wayland グリーター (`noctalia-greeter`, `tuigreet`, `regreet` 等) の資産を活かし，GDM 相当の「パスワード入力と指紋タッチの同時待ち受け」を実現する．
- `greetd` デーモン本体を，マルチワーカー・レース調停エンジンを備えた Rust 製の軽量互換デーモン (`greetd-parallel`) として再設計・自己実装するアプローチを採る．

```mermaid
flowchart TD
    G["Greeter (noctalia-greeter / tuigreet)<br/>greetd-ipc クライアント"]

    subgraph Master ["greetd-parallel (Master Daemon: Root)"]
        IPC["UNIX Socket Server<br/>(GREETD_SOCK)"]
        ARB["Arbiter (レース調停エンジン)<br/>tokio::select!"]
    end

    subgraph Workers ["認証ワーカー (子プロセス分離)"]
        PW["Password Worker<br/>[pam/greetd-password]<br/>pam_unix (pam_fprintd なし)"]
        FP["Fingerprint Worker<br/>D-Bus or [pam/greetd-fingerprint]"]
    end

    G <-->|greetd-ipc| IPC
    IPC <--> ARB
    ARB -->|spawn / pipe| PW
    ARB -->|spawn / D-Bus| FP

    ARB -->|勝者確定| SESS["pam_open_session() →<br/>setuid() → Wayland Compositor 起動"]
    ARB -->|敗者破棄| KILL["SIGTERM / ReleaseDevice"]
```

---

## 2. greetd-ipc プロトコルの分析と課題

### 2.1 既存の `greetd-ipc(7)` 仕様
greetd の IPC は JSON を長さ付きプレフィックス (4 バイト，ネイティブバイトオーダーの `u32`) でやり取りする同期型プロトコルである (`greetd_ipc` の `u32::from_ne_bytes`)．

- クライアント $\to$ サーバー:
  - `create_session { username }`
  - `post_auth_message_response { response }`
  - `start_session { cmd, env }`
  - `cancel_session`
- サーバー $\to$ クライアント:
  - `success`
  - `error { error_type, description }`
  - `auth_message { auth_message_type, auth_message }`

### 2.2 設計上の課題: サーバー主導の非同期通知の欠如
既存のプロトコルは厳密な Request-Response 型 (同期 RPC) である．
1. クライアントが `create_session` を送る．
2. サーバーが `auth_message ("Password: ")` を返す．
3. クライアントは UI 上でキー入力を待ち，Enter が押されるまでソケットに何も送信しない．

ユーザーがパスワードを入力せずに指紋センサーにタッチした場合:
- デーモン側で指紋認証が成功する．
- greeter クライアントは `post_auth_message_response` を送信するのを待機している．
- オリジナルの greetd-ipc 仕様には，クライアントからのリクエストがない状態でサーバーが自発的に認証成功を通知するイベント機構が存在しない．

---

## 3. プロトコル互換アプローチの比較

| 方式 | 仕組み | グリーター側の改修 | 互換性・安定性 |
| :--- | :--- | :--- | :--- |
| A. 投機的レスポンス送信<br>(完全無改造互換) | クライアントが `post_auth_message_response` を送る前に，指紋成功時点でソケットに `{"type":"success"}` を流し込む | 不要 (無改造) | グリーターの実装依存．ソケットをイベントループで `poll` しているグリーターなら通るが，同期 `write` $\to$ `read` で書かれているとデッドロックやプロトコル不整合を起こす |
| B. スーパーセット拡張<br>(後方互換 + イベント拡張) | `create_session` に `capabilities: ["parallel"]` を追加．並行モード時はサーバーから非同期 `auth_status` / `event` を送信可能にする | 小規模改修<br>(noctalia-greeter に数十行) | 最も安定．未対応グリーターには従来の直列動作，対応グリーターには並行 UX を提供 |

---

## 4. アーキテクチャ設計仕様

### 4.1 コンポーネント構成

- 特権 Master Daemon (Root) が `/run/greetd-<PID>.sock` をリッスンし (パスは `GREETD_SOCK` でグリーターへ渡される)，セッションライフサイクル管理 (`pam_open_session`, `pam_setcred`)，ユーザー権限への降格 (`setgid`, `initgroups`, `setuid`)，およびセッションプロセス (Niri や Hyprland) の `exec` を担う．
- Password Worker は `fork` + `exec` された隔離プロセスとして動作し，専用の `/etc/pam.d/greetd-password` (`pam_fprintd.so` を除外) を読み込んで `pam_unix` を同期実行する．
- Fingerprint Worker / D-Bus Controller は指紋照合を担い，Master プロセス内から `zbus` 経由で `net.reactivated.Fprint` を直接監視するか，あるいは `/etc/pam.d/greetd-fingerprint` を実行する独立子プロセスを spawn して制御する．
- Arbiter (調停エンジン) が `tokio::select!` により，Password Worker のパイプと Fingerprint の照合完了イベントをレース待ち受けする．

### 4.2 レース調停と敗者キャンセルの詳細シーケンス

```mermaid
sequenceDiagram
    participant G as Greeter (UI)
    participant M as greetd-parallel (Master)
    participant PW as Password Worker
    participant FW as Fingerprint (D-Bus)

    G->>M: CreateSession { username: "t3u" }
    M->>PW: spawn [pam/greetd-password]
    M->>FW: Claim & VerifyStart (D-Bus)
    PW->>M: Prompt: "Password: "
    M->>G: AuthMessage { "secret", "Password or fingerprint: " }

    Note over G: ユーザーが指紋センサーにタッチ！
    FW->>M: VerifyStatus: "verify-match" (勝者確定)

    rect rgb(240, 220, 220)
    Note over M,PW: 敗者キャンセル処理
    M->>PW: SIGTERM (Worker プロセス停止)
    M->>FW: ReleaseDevice (センサー解放)
    end

    M->>G: Success
    G->>M: StartSession { cmd: ["niri-session"] }
    M->>M: pam_open_session & setuid
    M->>M: execve("niri-session")
```

#### キャンセル処理の厳密なルール
- パスワード側が先行成立した場合は，直ちに D-Bus で `StopVerify()` および `Release()` を発行して指紋センサーを解放する．未解放のままだと `Device was already claimed` 状態が継続し，ログイン後の画面ロックで指紋認証が機能しなくなる．
- 指紋側が先行成立した場合は，Password Worker プロセスに `SIGTERM` を送信し，猶予時間 (例: 200ms) を超えたら `SIGKILL` で強制終了する．Password 側の会話破棄に伴う `pam_faillock` の誤カウントを防ぐため，`greetd-password` 設定側には `audit` や `fail_interval` の影響を局所化する設定を施しておく．

---

## 5. GNOME Keyring / 暗号鍵問題への対処

並行認証において，指紋で勝った場合はメモリ上に平文パスワードが存在しない．
このため，ログイン時に `pam_gnome_keyring` がログインキーリングを解錠できないという原理的制約が生じる．

### 現実的な 3 つの設計パターン
- GDM 方式のように指紋ログイン時は Keyring をロックしたまま起動し，後から Secret Service を要求するアプリが起動した時点でパスワード入力を促す (ログイン後フォールバック)．
- GNOME 51 のように初回ログインではパスワード入力を必須とし，指紋並行認証は画面ロック解除のみに限定する．
- 指紋照合成功を契機に TPM2 や Secure Enclave から暗号化シークレットをアンラップして Keyring に注入する (TPM2 / FIDO2 HMAC-secret 連携，カスタム PAM モジュールを要する)．

---

## 6. 実装規模と工数見積もり

Rust を用いてゼロから `greetd-parallel` を自己実装する場合の見積もりである．

| コンポーネント | 想定コード量 (Rust) | 実装内容・技術要素 |
| :--- | :--- | :--- |
| IPC サーバー | 約 300〜400 行 | `tokio::net::UnixListener`, `greetd-ipc` の JSON パース・シリアライズ |
| PAM Worker | 約 300〜500 行 | `fork` + `exec`，パイプ経由の同期 PAM 会話 (`pam` crate 併用) |
| D-Bus 指紋監視 | 約 200〜300 行 | `zbus` による `net.reactivated.Fprint` の非同期 Claim / VerifyStart / シグナル監視 |
| Arbiter & 調停 | 約 300〜400 行 | レース調停 (`tokio::select!`)，子プロセスのシグナル終了，タイムアウト管理 |
| セッションランナー | 約 300〜400 行 | `pam_open_session`, `pam_setcred`, `setuid`，環境変数注入，`execve` |
| 合計 | 約 1,400〜2,000 行 | 一般的な Rust デーモンの小〜中規模レベル |

### 既存の参考実装・流用元
- `greetd` 本体のリポジトリ (Kenny Levinsen) から IPC プロトコル定義 (`greetd_ipc` crate) や環境変数処理をそのままクレートとして利用可能．
- GDM の `gdm-session-worker.c` および hyprlock の `Fingerprint.cpp` からセンサー競合回避のステートマシン設計を流用可能．

---

## 7. NixOS での統合・導入手順

NixOS では `services.displayManager.greetd` モジュールが提供されているため，独自実装したデーモンパッケージへの差し替えはシンプルである．

```nix
# 自作デーモンの差し替え例 (configuration.nix / host module)
{ pkgs, ... }:
{
  services.displayManager.greetd = {
    enable = true;
    package = pkgs.callPackage ./pkgs/greetd-parallel { }; # 自作バイナリに置換
    settings = {
      default_session = {
        command = "${pkgs.noctalia-greeter}/bin/noctalia-greeter";
        user = "greeter";
      };
    };
  };

  # 並行認証用の分割 PAM 設定
  security.pam.services = {
    greetd-password = {
      text = ''
        auth include login
      ''; # pam_fprintd は含まない
    };
    greetd-fingerprint = {
      text = ''
        auth required pam_fprintd.so
      '';
    };
  };
}
```

---

## 8. 結論: 自己実装すべきか否かの判断基準

- GDM が 15 年間運用してきた dual-worker アーキテクチャを Rust で再実装する形となるため，技術的実現性は高く，単一スタックの未定義動作や SEGV クラッシュを回避できる．
- `noctalia-greeter` や `tuigreet` をそのまま活かしながら，ログイン画面でパスワード・指紋の即時解錠体験を得られる利点がある．
- 一方で，約 1,500〜2,000 行の特権デーモンの保守責任が発生することや，指紋ログイン時に GNOME Keyring が解錠されずデスクトップ起動後にパスワード要求ダイアログが出るというトレードオフを伴う．

推奨:
日常の利便性向上を目的とする場合，まずは工数が最小 (数十行) で Keyring の問題も起きない「Noctalia ロック画面のデュアルチャネル並行化」を優先し，ログイン画面の並行化が必要になった段階で，本設計仕様に基づく `greetd-parallel` の PoC 実装に着手するのが有効である．

---

## 関連ドキュメント

- [parallel-auth-upstream-history.md](parallel-auth-upstream-history.md) — 各 upstream の並行化の歴史と挫折理由
- [parallel-auth-architecture.md](parallel-auth-architecture.md) — 単一 PAM スタックの逐次性と各種実装比較
- [nixos/services/desktop/greetd.nix](../../nixos/services/desktop/greetd.nix) — 本リポジトリの greetd / PAM 設定
