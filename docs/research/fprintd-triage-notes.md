# fprintd トリアージ記録（x1c7，2026-10-15）

本ドキュメントは，ホスト `x1c7` 上で実機ログ・sysfs・実行時状態を直接採取して行った fprintd のトリアージ結果を記録したものである．各事象の判定と根拠，および一次ソース（upstream のソースコード）に基づく切り分けを示す．

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
- 当日の長時間稼働（07:36–07:54）は並行して動いている別ワーカーが pkexec を連投して Claim を繰り返したためで，通常状態ではない．

### 2. polkit-1 / sudo の PAM 順序 — Direct Root Cause
- `/etc/pam.d/polkit-1`・`/etc/pam.d/sudo`・`/etc/pam.d/su` はいずれも
  `auth sufficient pam_fprintd.so`（order 11400）→ `auth sufficient pam_unix ... try_first_pass`（11700）．
- `pam/pam_fprintd.c`: `DEFAULT_TIMEOUT 30`，`DEFAULT_MAX_TRIES 3`．パスワードを読む `conv` は持たず `PAM_TEXT_INFO`（"Place your finger..."）しか送らない．タイムアウト時は `PAM_AUTHINFO_UNAVAIL` を返して次モジュールへ落ちる．
- したがって指を置かない限り **最大 30 秒** パスワード入力欄が出ない．実測: トリアージ中に実行した `sudo ls /proc/9706/fd` は 30 秒でタイムアウトするまで戻らなかった（指紋待ち）．
- `greetd` だけは commit `0ae6aae`/`d09c7ac` で `unix` を先・`use_first_pass` に変更済み．`polkit-1`/`sudo`/`su` には未適用．
- 副次効果: pam_fprintd が最大 30 秒デバイスを Claim し続けるため，同時に複数の認証要求が来ると後続が `Device was already claimed` で即失敗し，パスワードへ落ちる．

### 3. 指紋不一致 / MoC テンプレート — Working as Designed
- ログの `Failed to match fingerprint`（pam_fprintd / greeter / polkit-kde）は `verify-no-match` の正常通知．Synaptics ドライバは `fpi_print_set_device_stored(print, TRUE)` で照合をチップ内で行い，不一致時 `BMKT_FP_NO_MATCH` → `FPI_MATCH_FAIL` を返す．
- テンプレート破損の形跡はなし．`fprintd-list` は 2 指を列挙でき，resume 後に `claimed`→`released`→`session unlock requested` が成立している．
- MoC はこのデバイスの設計そのもの．不一致は未登録指・置き方の問題．

### 4. suspend/resume の stale USB ハンドル — Ruled Out / Mitigated
- resume 時に `xhci_hcd 0000:2d:00.0: xHC error in resume, USBSTS 0x401, Reinit` が出て USB が再初期化される（カーネル/BIOS 側の既知挙動）．
- しかし Noctalia は resume 後に `using fingerprint device` → `claimed` → `released` と毎回新しいハンドルで Claim し直す．fprintd 自体は 30 秒で終了し suspend 中は保持しないため，resume サービスは不要．
- `power/control=on` / `power/persist=1`（udev）と TLP denylist が 2026-10-09 に導入済み．stale ハンドル系エラー（`No such device`，`get_usbfs_fd`，`unsupported firmware version`）の最終発生は 2026-09-29 で，以降なし．
- 参考: 2026-09-29 に fprintd の SIGSEGV が 1 回だけ記録（`fprintd.service: Failed with result 'core-dump'`）．再発なし．

### 5. Noctalia ロック画面の stopVerify / Claim 保持 — Working as Designed
- ログは `claimed fingerprint device` → `released fingerprint device` を必ず対で出しており，解放漏れはない．
- `Verification was in progress, stopping it` は fprintd `device.c` の `fprint_device_release()` が出す警告で，**Release 中に進行中 verify を正しくキャンセルした** という意味．Noctalia に明示的な VerifyStop は不要．
- 当日 07:52–07:54 の `Device was already claimed` 連発は，並行ワーカーが pkexec（=pam_fprintd）を連投し，最初の Claim が timeout までデバイスを保持したため．単一の認証では発生しない．同時認証が重なる状況でのみ Conditional．

### 6. polkit エージェント衝突 — Ruled Out / Mitigated
- 実効エージェントは `niri-flake-polkit.service`（user unit）が起動する `polkit-kde-authentication-agent-1`（cgroup: `.../niri-flake-polkit.service`）．
- Noctalia は `[app] polkit agent disabled: ... An authentication agent already exists` を出して自主的に無効化．polkit 認証自体は KDE エージェントで正常動作するためユーザー影響なし．
- `home/desktop/noctalia/default.nix` の `polkit_agent = true` は実質無効（設定の重複）．

### 7. USB autosuspend / TLP — Ruled Out / Mitigated
- `/sys/bus/usb/devices/1-9/`: `power/control=on`，`power/persist=1`，`power/autosuspend=2`（control=on のため autosuspend は無効化）．
- udev ルール（[`hosts/x1c7/default.nix`](../../hosts/x1c7/default.nix)）が適用済み．TLP は `USB_DENYLIST="06cb:00bd"`（`/run/tlp/run.conf`，`/etc/tlp.conf`）．
- 二重に防止済みで，これ以上の対処は不要．

### 8. error 789 — Working as Designed
- `synaptics.c` の probe 冒頭，SENSOR_CMD_GET_VERSION の初回応答 status が 0 以外だと `g_warning ("Device responded with error: %d retry: %d", status, retry)` を出して **1 回だけ即リトライ** する（`retry` 初期値 TRUE → FALSE）．リトライは常に成功し probe は継続．
- 発生は電源投入後やデバイス初期化後の最初の 1 回のみ．集計: 直近 57 boot 中 46 boot で各 1 回（boot あたり最大 1）．severity は warning であり照合結果には影響しない．
- 789 = 0x0315 は Prometheus ファームウェアが返す初回ステータス．fprintd 側に既知の対処（リトライ）が入っている．

## 推奨アクション（トリアージ外・参考）

1. **polkit-1 / sudo / su の指紋 UX 修正**（最優先）．greetd と同様に `unix` を先に `use_first_pass` で評価するか，`pam_fprintd.so` に `timeout=` と `max-tries=` を付けて待ち時間を短縮する．NixOS の `security.pam.services.<name>.rules.auth.fprintd.settings` で指定可能．
2. Noctalia の `polkit_agent = true`（[`home/desktop/noctalia/default.nix`](../../home/desktop/noctalia/default.nix)）を削除するか，`niri-flake-polkit` を止めて一本化する（現状は KDE 側が勝ち，Noctalia 側は毎回無効化される）．
3. fprintd resume サービスは不要（追加しない）．
4. error 789 は監視のみ．fwupd で Synaptics ファームウェア更新が出ていないかは別途確認する価値がある．

---

## 関連ドキュメント

- [`parallel-auth-architecture.md`](parallel-auth-architecture.md) — 指紋 + パスワード並行待ち受けの可否と，GDM / Noctalia / greetd / polkit / sudo の実装比較
- [`bsd-auth-architecture.md`](bsd-auth-architecture.md) — BSD 系（OpenPAM / BSD Authentication）の同期性・並行性の調査
- [`thinkpad-x1c7.md`](../hardware/thinkpad-x1c7.md) — x1c7 の指紋認証・PAM 統合の現状
