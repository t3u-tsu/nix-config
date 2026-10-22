# fprintd トリアージ記録（x1c7，2026-10-15）

ホスト `x1c7` の実機ログ，sysfs，実行時状態，および upstream ソースコードに基づく fprintd のトリアージ記録．各事象の判定，技術的根拠，および一次切り分けをまとめる．

## 環境

- Host: x1c7 / Kernel 6.18.56-xanmod1 / NixOS 26.05.20261012.7993f34
- fprintd 1.94.5 / libfprint 1.94.10 / Noctalia 5.2.1 / polkit 127 / polkit-kde-agent-1 6.6.6
- Sensor: Synaptics Prometheus MIS `06cb:00bd`（match-on-chip，テンプレートはデバイス内保存）
- 登録指: right-index-finger / left-index-finger（`fprintd-list t3u`）
- fprintd.service: `Type=dbus`，`BusName=net.reactivated.Fprint`，Idle 30 秒で自動終了（`src/fprintd.h: #define TIMEOUT 30`）

## 判定サマリ

| # | 項目 | 判定 |
| :- | :--- | :--- |
| 1 | D-Bus activation 30s auto-exit | Working as Designed |
| 2 | polkit-1 / sudo の PAM 順序 | **Direct Root Cause** |
| 3 | 指紋不一致 / MoC テンプレート | Working as Designed |
| 4 | suspend/resume の stale USB ハンドル | Ruled Out / Mitigated |
| 5 | Noctalia ロック画面の stopVerify / Claim 保持 | Working as Designed（競合時のみ Conditional） |
| 6 | polkit エージェント衝突 | Ruled Out / Mitigated |
| 7 | USB autosuspend / TLP | Ruled Out / Mitigated |
| 8 | error 789 | Working as Designed（良性ファームウェア応答） |

## 根拠

### 1. D-Bus activation 30s auto-exit — Working as Designed
- `fprintd.service` は `Type=dbus`．未使用 30 秒で `Deactivated successfully`（`manager.c` の `TIMEOUT 30`）．
- 必要時は systemd が D-Bus 経由で自動起動するため，`systemctl status fprintd` が普段 `inactive` でも機能上の問題はない．
- トリアージ当日の長時間稼働（07:36–07:54）は，別プロセスが pkexec を連続実行して Claim を維持したことによる一時的挙動である．

### 2. polkit-1 / sudo の PAM 順序 — Direct Root Cause
- `/etc/pam.d/polkit-1`，`/etc/pam.d/sudo`，`/etc/pam.d/su` はいずれも `auth sufficient pam_fprintd.so`（order 11400）→ `auth sufficient pam_unix ... try_first_pass`（11700）．
- `pam/pam_fprintd.c`: `DEFAULT_TIMEOUT 30`，`DEFAULT_MAX_TRIES 3`．`conv` は `PAM_TEXT_INFO`（"Place your finger..."）の送信のみに使用する．タイムアウト時は `PAM_AUTHINFO_UNAVAIL` を返して次モジュールへ落ちる．
- 指を置かない限り **最大 30 秒** パスワード入力欄が出ない．実測値: `sudo ls /proc/9706/fd` の実行時，指を置かない場合は 30 秒のタイムアウトまでパスワードプロンプトが表示されず待機状態となった．
- `greetd` は先行設定で `pam_unix` 優先（`use_first_pass`）に変更済みであったが，`polkit-1`，`sudo`，`su` は未適用であった．
- 副次効果: pam_fprintd が最大 30 秒デバイスを Claim し続けるため，同時に複数の認証要求が来ると後続が `Device was already claimed` で即座に失敗し，パスワード認証へ落ちる．

### 3. 指紋不一致 / MoC テンプレート — Working as Designed
- ログの `Failed to match fingerprint`（pam_fprintd / greeter / polkit-kde）は `verify-no-match` の正常通知である．Synaptics ドライバは `fpi_print_set_device_stored(print, TRUE)` で照合をチップ内で行い，不一致時に `BMKT_FP_NO_MATCH` → `FPI_MATCH_FAIL` を返す．
- テンプレート破損の形跡はない．`fprintd-list` は 2 指を正常に列挙でき，resume 後も `claimed` → `released` → `session unlock requested` の遷移が成立している．
- MoC はデバイスハードウェアの基本仕様であり，不一致ログは未登録指や接触不良に起因する正常通知である．

### 4. suspend/resume の stale USB ハンドル — Ruled Out / Mitigated
- resume 時に `xhci_hcd 0000:2d:00.0: xHC error in resume, USBSTS 0x401, Reinit` が記録され USB が再初期化される（カーネル / BIOS 側の既知挙動）．
- Noctalia は resume 後に `using fingerprint device` → `claimed` → `released` と毎回新しいハンドルで Claim し直す．fprintd 自体は 30 秒で自動終了し suspend 中は保持しないため，専用の resume 復帰サービスは不要である．
- `power/control=on` / `power/persist=1`（udev）と TLP denylist が 2026-10-09 に導入済みである．stale ハンドル系エラー（`No such device`，`get_usbfs_fd`，`unsupported firmware version`）は 2026-09-29 を最後に発生していない．
- 2026-09-29 に fprintd の SIGSEGV が 1 回記録されたが（`fprintd.service: Failed with result 'core-dump'`），以降の再発は確認されていない．

### 5. Noctalia ロック画面の stopVerify / Claim 保持 — Working as Designed
- ログは `claimed fingerprint device` → `released fingerprint device` を必ず対で出力しており，解放漏れはない．
- `Verification was in progress, stopping it` は fprintd `device.c` の `fprint_device_release()` が出す警告であり，Release 処理中に進行中の verify を正常にキャンセルしたことを意味する．Noctalia 側での明示的な VerifyStop は不要である．
- 当日 07:52–07:54 の `Device was already claimed` 多発は，並行プロセスが pkexec（`pam_fprintd`）を連続実行し，先行 Claim がタイムアウトまでセンサを占有したことによる．単一プロセスの認証では発生せず，競合時のみ生じる一時的挙動である．

### 6. polkit エージェント衝突 — Ruled Out / Mitigated
- 実効エージェントは `niri-flake-polkit.service`（user unit）が起動する `polkit-kde-authentication-agent-1`（cgroup: `.../niri-flake-polkit.service`）である．
- Noctalia は `[app] polkit agent disabled: ... An authentication agent already exists` を出力して自主的に無効化する．polkit 認証自体は KDE エージェントで正常動作するためユーザー影響はない．
- `home/desktop/noctalia/default.nix` の `polkit_agent = true` は実質無効（重複設定のため不要）．

### 7. USB autosuspend / TLP — Ruled Out / Mitigated
- `/sys/bus/usb/devices/1-9/`: `power/control=on`，`power/persist=1`，`power/autosuspend=2`（control=on のため autosuspend は無効化）．
- udev ルール（[`hosts/x1c7/default.nix`](../../hosts/x1c7/default.nix)）が適用済み．TLP は `USB_DENYLIST="06cb:00bd"`（`/run/tlp/run.conf`，`/etc/tlp.conf`）．
- udev と TLP の双方で抑止されており，追加の対処は不要である．

### 8. error 789 — Working as Designed
- `synaptics.c` の probe 冒頭，SENSOR_CMD_GET_VERSION の初回応答 status が 0 以外だと `g_warning ("Device responded with error: %d retry: %d", status, retry)` を出力して **1 回だけ即時リトライ** する（`retry` 初期値 TRUE → FALSE）．リトライは常に成功し probe 処理は継続する．
- 発生は電源投入後やデバイス初期化後の最初の 1 回のみである．直近 57 boot 中 46 boot で各 1 回記録（boot あたり最大 1 回）．severity は warning であり照合結果には影響しない．
- 789（0x0315）は Prometheus ファームウェアが返す初期化ステータスであり，ドライバ層でリトライによる回復処理が実装されている．

## 推奨アクション（トリアージ実施時の所見）

1. **polkit-1 / sudo / su の指紋 UX 改善**: greetd と同様に `pam_unix` を優先するか，`pam_fprintd.so` の `timeout` / `max-tries` を短縮して待機時間を削減する（`security.pam.services.<name>.rules.auth.fprintd.settings` で指定可能）．
2. **polkit エージェント設定の一本化**: Noctalia の `polkit_agent` 設定（[`home/desktop/noctalia/default.nix`](../../home/desktop/noctalia/default.nix)）を無効化するか，`niri-flake-polkit` を停止して競合を防ぐ（現状は KDE エージェントが優先され Noctalia 側は無効化されている）．
3. **resume サービスの不採用**: fprintd は D-Bus 自動終了と復帰時の再 Claim で正常動作するため，個別復帰サービスは追加しない．
4. **error 789 の扱い**: ドライバ層で回復するため実害はなく静観とする．ファームウェア更新の有無については fwupd で継続確認する．

---

## 関連ドキュメント

- [`parallel-auth-architecture.md`](parallel-auth-architecture.md) — 指紋 + パスワード並行待ち受けの可否と，GDM / Noctalia / greetd / polkit / sudo の実装比較
- [`bsd-auth-architecture.md`](bsd-auth-architecture.md) — BSD 系（OpenPAM / BSD Authentication）の同期性・並行性の調査
- [`thinkpad-x1c7.md`](../hardware/thinkpad-x1c7.md) — x1c7 の指紋認証・PAM 統合の現状
