# BSD 認証アーキテクチャ：同期か並行か

FreeBSD（OpenPAM），NetBSD（OpenPAM），OpenBSD（BSD Authentication）の認証スタックは，いずれも厳密に同期・逐次処理であり，生体認証とパスワードの並行待ち受けプリミティブを持たない．

- **FreeBSD / NetBSD (OpenPAM)**: Linux-PAM と同様の「モジュールチェーンを順次辿る単一スレッドループ」であり，PAM ハンドルごとに単一の conversation コールバックのみを持つ．FreeBSD の生体認証は ports の `security/fprintd`（`pam_fprintd.so`）による逐次実行にとどまり，NetBSD には fprintd パッケージ自体が存在しない．
- **OpenBSD (BSD Authentication)**: socketpair 経由で特権分離された外部ヘルパプロセスを起動するモデルを採るが，1 回の試行につき 1 スタイルのみを選択し，単一ヘルパを `waitpid()` でブロック待機する逐次構造である．生体認証の統合機構は base システムに存在しない．
- **縦統合の境界**: いずれの BSD もカーネル＋base ユーザランドのみを垂直統合しており，デスクトップ環境や認証 UI は ports / pkgsrc の管轄となる．そのため，ディスプレイマネージャや認証プロンプトを横断して並行待ち受けをオーケストレーションする基盤が存在しない．

---

## 1. FreeBSD と NetBSD — OpenPAM

OpenPAM は FreeBSD（`contrib/openpam`）と NetBSD（`external/bsd/openpam/dist`）が採用するリファレンス実装である．Dag-Erling Smørgrav が開発し，X/Open Single Sign-on（XSSO）PAM 仕様，Solaris PAM，Linux-PAM を起源とする．README には次の記述がある:

> OpenPAM is an open source PAM library that focuses on simplicity, correctness,
> and cleanliness. [...] In areas where these implementations disagree, OpenPAM
> tries to remain compatible with Solaris, at the expense of XSSO conformance and
> Linux-PAM compatibility.

### 1.1 `openpam_dispatch()` は逐次チェーン走査

`contrib/openpam/lib/libpam/openpam_dispatch.c`（FreeBSD）にモジュールディスパッチの全ロジックが入っている．プリミティブに対応するチェーンを選択した後，モジュールの連結リストを単一の `for` ループで回し，各モジュール関数を順に呼ぶ:

```c
/* prevent recursion */
if (pamh->current != NULL) {
    openpam_log(PAM_LOG_ERROR,
        "%s() called while %s::%s() is in progress", ...);
    RETURNC(PAM_ABORT);
}
...
for (; chain != NULL; chain = chain->next) {
    ...
    r = (chain->module->func[primitive])(pamh, flags,
        chain->optc, (const char **)(intptr_t)chain->optv);
    ...
    if (r == PAM_IGNORE)
        continue;
    if (r == PAM_SUCCESS) {
        ++nsuccess;
        if ((chain->flag == PAM_SUFFICIENT ||
             chain->flag == PAM_BINDING) && !fail && ...)
            break;
        continue;
    }
    ...
    if (chain->flag == PAM_REQUISITE) {
        ...
        break;
    }
}
```

**ディスパッチ構造の特徴**:

- **厳密な逐次実行**: 1 つのモジュールの完了を待ってから次が呼ばれる．スレッドや `select()` / `poll()` による多重化はなく，複数モジュールを競合させる機構は存在しない．
- **再入・並行性の排除**: `pamh->current != NULL` ガードにより，ディスパッチ実行中のネストした `pam_*` 呼び出しは `PAM_ABORT` で拒絶される．単一の PAM ハンドルが保持できるディスパッチ状態は常に 1 つに限られる．
- **制御フラグの性質**: `PAM_REQUISITE`，`PAM_SUFFICIENT`，`PAM_BINDING` の各フラグは，ループの走査順序と早期終了条件を制御するのみであり，並行実行をもたらさない．
- **NetBSD との共通性**: NetBSD の `openpam_dispatch.c` も同一実装である．FreeBSD との差分は `__RCSID()` の追加と `(enum openpam_sm_primitives)` キャストのみであり，ループ本体（`for (; chain != NULL; chain = chain->next)`）は完全に一致する．

### 1.2 PAM ハンドルごとに conversation コールバックは 1 つ

アプリケーションは `pam_start()` 時にコールバックを 1 つだけ渡す．OpenPAM はそれをハンドルの `PAM_CONV` アイテムとして保持する（`contrib/openpam/lib/libpam/pam_start.c`）:

```c
int pam_start(const char *service, const char *user,
    const struct pam_conv *pam_conv, pam_handle_t **pamh)
{
    ...
    if ((r = pam_set_item(ph, PAM_CONV, pam_conv)) != PAM_SUCCESS)
        ...
}
```

`pam_conv(3)` は，すべてのモジュールがこのアプリケーション提供の単一関数を通じてユーザと対話することを記述している:

```c
struct pam_conv {
    int (*conv)(int, const struct pam_message **,
                struct pam_response **, void *);
    void *appdata_ptr;
};
```

モジュールは 1 回のコールバック呼び出しにメッセージの*配列*を渡せる（`PAM_MAX_NUM_MSG` まで）ため，複数の質問をまとめられる．しかしコールバックはモジュール内部から同期的に 1 回呼ばれるだけで，PAM ハンドルごとに conversation 関数は常に 1 つである．イベントループではなく，2 つのモジュールが同時にプロンプトを出すことはできない．

### 1.3 Linux-PAM との比較

Linux-PAM の `_pam_dispatch_aux()`（`libpam/pam_dispatch.c`）は，ハンドラスタックを同じように逐次走査する:

```c
/* Loop through module logic stack */
for (depth=0 ; h != NULL ; prev_level = stack_level, h = h->next, ++depth) {
    ...
    retval = h->func(pamh, flags, h->argc, h->argv);
    ...
}
```

このように，Linux と BSD の PAM 実装はいずれも同期・単一コールバックのパイプラインを共有する．相違点として，Linux-PAM は `PAM_INCOMPLETE` を定義しており，モジュールが内部状態を保持してアプリケーションへ制御を戻し，後から再開する協調的ディスパッチが可能である．一方，OpenPAM は `PAM_INCOMPLETE` を定義していないため（`contrib/openpam/include/security/pam_constants.h` に該当定数なし），ディスパッチは完全にブロッキング処理となる．ただし Linux-PAM の再開機構も単一スタックの進行を一時中断するにすぎず，複数モジュールの並行実行を支援するものではない．

### 1.4 FreeBSD / NetBSD の生体認証

- **FreeBSD**: port `security/fprintd`（現在 1.94.4）が freedesktop の `fprintd` D-Bus デーモン*と* `lib/security/pam_fprintd.so` を提供し，バックエンドは `security/libfprint` である．Linux と同じ upstream スタックをそのまま移植したもので，FreeBSD base には入っていない．FreeBSD の認証は OpenPAM なので，`pam_fprintd` は PAM スタック内の 1 モジュールにすぎず，`pam_unix`/`pam_ssh` 等と順番に呼ばれる．指紋プロンプトとパスワードプロンプトを競争させるフレームワーク支援は無い．
- **NetBSD**: pkgsrc は `security/libfprint` を提供するが，`security/fprintd` パッケージは**無い**．したがって NetBSD にはパッケージ化された生体認証ログインデーモン／PAM モジュールが存在しない．
- どちらも base で OpenPAM を使う．これらのシステムの OpenSSH は BSD auth ではなく `pam` デバイスを使う．

---

## 2. OpenBSD — BSD Authentication（`bsd_auth(3)`，`login_*`）

### 2.1 OpenBSD が PAM を採用しなかった理由

BSD Authentication は BSD/OS（BSDI）に起源を持ち，FreeBSD を経て OpenBSD 2.9 で採用された．OpenBSD が base システムで PAM を排した設計理由は以下のとおりである．

1. **特権アドレス空間内の共有ライブラリ**．PAM モジュールは `dlopen` される動的共有オブジェクトであり，認証を行うプロセス*内部*で動作する．`login`，`su`，`sshd`，`passwd`，`ftpd` では，そのプロセスが setuid/setgid root か，それに準ずる高い特権を持つ．モジュールのバグ・バックドア・メモリ安全性の誤りは，呼び出し元の特権とアドレス空間をそのまま得て実行される．隔離境界が存在しない．この危険性は "the fact that it's a shared library means that any vulnerability in a poorly vetted authentication module gives attackers direct access to the internals of your application." と要約される．
2. **構造としての特権分離**．BSD Auth は各認証スタイルを*独立した実行ファイル*として起動し，狭い IPC チャネルで通信する．これは Provos, Friedl, Honeyman の "Preventing Privilege Escalation"（USENIX Security 2003）に記述された原則と同じであり，BSD Auth はその着想元として引用されている．独立プロセスはさらに `pledge(2)`/`unveil(2)` で特権を落とせる．例えば `libexec/login_passwd/login_passwd.c` は次のようにする:
   ```c
   /* get the password hash before pledge(2) or it will return '*' */
   pwd = getpwnam_shadow(username);
   if (pledge("stdio rpath tty id", NULL) == -1) { ... }
   ...
   if (pledge("stdio rpath", NULL) == -1) { ... }
   ```
   このようなサンドボックス化はプロセス内で動く PAM モジュールには不可能である．
3. **複雑さ・設定ミス**．PAM の階層化された `pam.conf`/`pam.d` 制御フラグとモジュールスタックは設定を誤りやすい（Michael W. Lucas の言う "unstandardized black magic"）．OpenBSD は `login.conf(5)` の小さく監査可能な設定と，単一目的のヘルパプログラムを好む．
4. **文化的・保守的な立場**．`pppd` から PAM の残骸を削除した OpenBSD `tech@` のスレッドで，Ted Unangst は「我々には無関係な PAM と shadow のコードが大量にある」と述べ，削除対象を "tangly morass" と呼んだ．置き換え先は BSD auth か素の `crypt_checkpass` であった．

なお，OpenBSD の ports ツリーには，PAM を要求する外部ソフトウェアのビルド用に `security/openpam`（および `security/libfprint`）が提供されている．排除の対象はあくまで base システムである．

### 2.2 アーキテクチャ — 独立ヘルパ実行ファイル + バックチャネル

BSD Auth の API は libc にある: `lib/libc/gen/auth_subr.c`（低レベルセッション API，`$OpenBSD: auth_subr.c,v 1.57 ...$`）と `lib/libc/gen/authenticate.c`（簡易インターフェース，`$OpenBSD: authenticate.c,v 1.30 ...$`）である．隠しシンボルのヘッダ `lib/libc/hidden/bsd_auth.h` は `auth_open`，`auth_call`，`auth_userokay`，`auth_verify` などをすべて libc シンボルとして列挙している．

スタイルは `/usr/libexec/auth/` 配下の独立プログラムである:

```c
/* include/login_cap.h */
#define _PATH_AUTHPROGDIR "/usr/libexec/auth"
#define _PATH_AUTHPROG    "/usr/libexec/auth/login_"
#define LOGIN_DEFSTYLE    "passwd"
#define LOGIN_DEFSERVICE  "login"
```

中核プリミティブは `auth_subr.c` の `auth_call()` である．fork してヘルパを exec し，子の fd 3 に socketpair を配線する（fd 4 は任意で fd 受け渡しに使う）:

```c
if (socketpair(PF_LOCAL, SOCK_STREAM, 0, pfd) == -1) { ... }

switch (pid = fork()) {
case 0:
#define COMM_FD 3
#define AUTH_FD 4
    if (dup2(pfd[1], COMM_FD) == -1) ...
    if (as->fd != -1) { if (dup2(as->fd, AUTH_FD) == -1) ...; closefrom(AUTH_FD + 1); }
    else closefrom(COMM_FD + 1);
    execve(path, argv, auth_environ);
    ...
default:
    close(pfd[1]);
    ...
    _auth_spool(as, pfd[0]);
    close(pfd[0]);
    do {
        if (waitpid(pid, &status, 0) != -1) {
            if (!WIFEXITED(status)) goto fail;
            break;
        }
    } while (errno == EINTR);
}
```

親は spool された応答を，`include/login_cap.h` で定義された行指向の `BI_*` トークンについて走査する:

```c
#define BI_AUTH        "authorize"        /* Accepted authentication */
#define BI_REJECT      "reject"           /* Rejected authentication */
#define BI_CHALLENGE   "reject challenge" /* Reject with a challenge */
#define BI_SILENT      "reject silent"    /* Reject silently */
#define BI_ROOTOKAY    "authorize root"
#define BI_SECURE      "authorize secure"
#define BI_SETENV      "setenv"
#define BI_VALUE       "value"
#define BI_EXPIRED     "reject expired"
#define BI_PWEXPIRED   "reject pwexpired"
#define BI_FDPASS      "fd"
```

子の環境は固定されている（`PATH`，`SHELL` のみ）．ヘルパは成功時に `BI_AUTH` を出力して 0 で終了し，失敗時は `BI_REJECT`/`BI_CHALLENGE`/... を出力して非 0 で終了する．同梱スタイルはすべて独立した実行ファイルである:

```text
/usr/libexec/auth/login_passwd    standard password
/usr/libexec/auth/login_skey      S/Key one-time passwords
/usr/libexec/auth/login_token     ActivCard/CRYPTOCard/SNK-004 tokens
/usr/libexec/auth/login_yubikey   YubiKey OTP
/usr/libexec/auth/login_radius    RADIUS
/usr/libexec/auth/login_ldap      LDAP bind/search
/usr/libexec/auth/login_chpass    forced password change
/usr/libexec/auth/login_lchpass   local password change
/usr/libexec/auth/login_reject    unconditional reject
```

これらは mode `4555`，owner `root`，group `auth` でインストールされる（`libexec/login_passwd/Makefile`）．このスタイル群は明らかにサーバ・クレデンシャル指向である: パスワード，ワンタイムパスワード，ハードウェアトークン，RADIUS，LDAP であり，デスクトップの生体認証ではない．

### 2.3 逐次選択 — 1 スタイル・1 ヘルパ・1 試行

高レベルのエントリポイントは `authenticate.c` にある:

- `auth_usercheck(name, style, type, password)` — 主要な処理経路．
- `auth_userokay(...)` — `auth_usercheck` + `auth_close` で yes/no を返す．
- `auth_userchallenge` / `auth_userresponse` — 2 フェーズの challenge/response．
- `auth_verify(as, style, name, ...)` — スタイルヘルパを直接 exec する．
- `auth_approval` — `approve-<type>`/`approve` スクリプトを実行する．

`auth_usercheck()` は `login_getstyle()` で要求を正確に 1 スタイルへ縮約し，`auth_verify()` を 1 回呼ぶ:

```c
if ((lc = login_getclass(pwd ? pwd->pw_class : NULL)) == NULL)
    return (NULL);
if ((style = login_getstyle(lc, style, type)) == NULL) {
    login_close(lc);
    return (NULL);
}
...
as = auth_verify(as, style, name, lc->lc_class, (char *)NULL);
```

`auth_verify()` は単一のパスを組み立て，`auth_call()` を 1 回呼ぶ:

```c
snprintf(path, sizeof(path), _PATH_AUTHPROG "%s", style);
...
auth_call(as, path, auth_getitem(as, AUTHV_STYLE), "-s",
    auth_getitem(as, AUTHV_SERVICE), "--", name, (char *)NULL);
```

`lib/libc/gen/login_cap.c` の `login_getstyle()` は，`login.conf(5)` のカンマ区切り `auth` / `auth-<type>` capability リストを解析するが，返すのは**単一**のスタイル文字列である．呼び出し元がスタイルを指定した場合はそれを，無ければリストの先頭要素を返す:

```c
if (!style)
    style = authtypes[0];
while (*authtypes && strcmp(style, *authtypes))
    ++authtypes;
if (*authtypes) {
    lc->lc_style = strdup(*authtypes);
    ...
}
```

`login.conf(5)` もこれに沿って capability を記述している: "`auth` (list, default `passwd`): Allowed authentication styles. **The first value is the default style.**"

利用側の `login(1)`（`usr.bin/login/login.c`，`$OpenBSD: login.c,v 1.75 ...$`）は，対話的な試行ごとにリトライループ内でこれを 1 回呼ぶ:

```c
style = login_getstyle(lc, style, type);
...
auth_verify(as, style, NULL, lc->lc_class, NULL);
authok = auth_getstate(as);
...
if ((authok & AUTH_ALLOW) == 0)
    goto failed;
```

`failed:` はユーザに再プロンプトしてループする．**複数スタイルを回すループは無い**: 各試行は `style`（任意の `user:style` 接頭辞，無ければ先頭／既定のスタイル）を再導出し，ヘルパを正確に 1 つ実行する．管理者が `auth = yubikey,passwd` と列挙しても，ユーザが明示的に `user:style` と入力しない限り `login` は先頭のみを使う．多要素構成は，内部で両方を処理する単一ヘルパか，サービスごとに選択される `auth-type` リストとして表現され，並行レースとして表現されることは決してない．

`su(1)`，`passwd(1)`，OpenSSH の `bsd_auth` バックエンド（`auth-bsdauth.c`，`auth_userokay` を呼ぶ）も同様に，それぞれ 1 スタイルを選ぶ．

### 2.4 `bsd_auth` は逐次か並行か

厳密に逐次である:

- `auth_call()` はヘルパを正確に 1 つ fork し，終了まで `waitpid()` でブロックする．フレームワークはイベントループではなく同期 RPC である．
- バックチャネルは 1 つの `socketpair` で，応答は最大 8 KiB まで完全に spool されてから解析される．
- `AUTH_CHALLENGE` 対応は 2 フェーズだが依然直列なプロトコルである: `auth_challenge()` がヘルパを `-s challenge` で実行してチャレンジ文字列を取得し，アプリケーションは後で `auth_userresponse()` を呼び，ヘルパを `-s response` と応答データ付きで再実行する．1 スタイル・1 ヘルパずつで，その間はブロックする．
- 複数ヘルパや複数デバイス fd に対する `select()`/`poll()`/スレッドは無い．

### 2.5 生体認証とパスワードの並行待ち受け可否

BSD Auth フレームワーク経由での並行待ち受けは不可能である．複数スタイルを同時に開始して先に成立した側を採用する API は存在しない．新規スタイルヘルパ（例: `login_fprint`）を作成し，その内部で指紋リーダーと端末プロンプトを競合させる実装は理論上可能だが，以下の構造的制約がある．

- OpenBSD base に生体認証用ヘルパは同梱されていない．
- 親プロセス側から見れば単一スタイル・単一ブロッキング子プロセスにすぎず，並行処理はヘルパ内部に閉じる．
- デバイスアクセスと `/etc/master.passwd` 参照のため特権プロセスを増設する必要があり，特権デーモンを最小化する OpenBSD の設計方針と背反する．

OpenBSD の ports には `security/libfprint` が存在するが，`fprintd` デーモンや PAM / BSD Auth 向けの指紋統合ヘルパは提供されておらず，パッケージ経由での生体認証ログイン手段も存在しない．

---

## 3. 縦統合のスコープとデスクトップ認証の不在

BSD プロジェクトにおける「縦統合（vertical integration）」の範囲は，**カーネル＋base ユーザランド**（単一リポジトリ，一元化されたリリースエンジニアリング，統一されたセキュリティ監査）に限定され，**デスクトップ環境**までは含まない．このアーキテクチャ境界が，並行マルチモーダル認証が実装されなかった直接の要因である．

### 3.1 縦統合が実際に止まる境界

- **FreeBSD**: base にはカーネル，libc，OpenPAM，`login`，`su`，`sshd` などが入る．デスクトップ（GNOME，KDE，Xfce，Wayland コンポジタ，ディスプレイマネージャ）は ports ツリーにあり，リリースとは独立にビルド・バージョン管理される．
- **NetBSD**: base には OpenPAM と `lib/libpam` が入り，`libfprint` は pkgsrc 経由でのみ存在する．
- **OpenBSD**: base には BSD Auth が入り，デスクトップは ports である．base は D-Bus，fprintd などのデスクトップデーモンを意図的に避ける．

どの BSD プロジェクトもファーストパーティのデスクトップシェルやディスプレイマネージャを持たない．したがってグラフィカルセッションへの認証は第三者ソフトウェア（GDM，SDDM，LightDM，greetd 等）が行い，まさにそのコンポーネントが「指紋かパスワードのどちらかを待つ」処理をオーケストレーションする必要がある．そのコンポーネントが縦統合された base の外にあるため，base のセキュリティ優先の認証設計が並行マルチモーダルプロンプトへ拡張されることはなかった．

### 3.2 Apple・Microsoft との対比

- **Apple**: Darwin/XNU は BSD 由来だが，Apple はその上のスタック全体を所有している．DirectoryService/OpenDirectory，Pluggable Authentication Modules と `CryptoTokenKit`，Touch ID 用の `LocalAuthentication`／Secure Enclave である．単一ベンダがカーネル，認証デーモン，ログインウィンドウ，センサーを制御するため，「指紋かパスワードの早い方」を構築するのは容易である．
- **Microsoft**: LSA + SSPI + Winlogon/Credential Providers である．Credential Provider（Windows Hello の顔・指紋・PIN）はすべてファーストパーティであり，パスワードフォールバックと並べて提供できる．

どちらの場合も，デスクトップと生体認証ハードウェア統合までを同梱する OS ベンダが存在する．BSD にはそのような主体がいない．

### 3.3 BSD がサーバ・ヘッドレス・セキュリティ最小主義に留まった理由

- base システムはサーバ，ファイアウォール，ルータ，メール/DNS 基盤，ヘッドレスコンソール向けに最適化されている．認証面（`login`，`su`，`sshd`，`ftpd`，`doas`/`sudo`，`passwd`）はコンソール／ネットワークのプロンプトである．
- 特に OpenBSD は，追加される特権デーモンをすべて攻撃面として扱う．D-Bus の `fprintd`，リーダデーモン，生体認証の PAM/BSD-auth モジュールを base に加えることは，その哲学と真っ向から矛盾する．
- FreeBSD と NetBSD は base を意図的に小さく保ち，デスクトップの関心事を ports/pkgsrc へ押し出す．そのため生体認証は*単一の PAM モジュール*（`pam_fprintd`）としてのみ到来し，逐次的な OpenPAM パイプラインを継承する．
- これらはボランティアプロジェクトであり，ハードウェア／センサーの要求を持たない．統一された並行生体認証プロンプトを構築するファーストパーティの動機が無く，Linux エコシステムの `fprintd` が既に port のニッチを埋めている．

### 3.4 結論

BSD における縦統合の目的はシステム全体の信頼性とセキュリティ規律の一元化であり，デスクトップのユーザー認証体験の垂直統合ではない．3 系すべてにおいてデスクトップおよびログイン UI は base システムの管理外（ports / pkgsrc）であり，base の認証フレームワーク（単純性と特権分離を重視した同期・単一コールバック設計）が並行マルチモーダル認証へ拡張される動機は存在しなかった．UI からカーネル・ハードウェアまでを一貫して所有・制御する Apple や Microsoft とはアーキテクチャの前提が異なる．

---

## 4. 調査設問への回答

| 設問 | 回答 |
| --- | --- |
| OpenPAM の `openpam_dispatch()` は Linux-PAM と同じ同期・逐次パイプラインか | 同期・逐次パイプラインである．モジュールチェーンに対する単一の `for` ループで 1 モジュールずつ順次実行し，`pamh->current` で再帰呼び出しを禁止する．なお Linux-PAM は `PAM_INCOMPLETE` による再開機構を備えるが，OpenPAM には存在しない． |
| `pam_conv` は Linux-PAM と同じ単一コールバックか | 単一コールバックである．`pam_start` 時に登録された `struct pam_conv` は PAM ハンドルごとに 1 個であり，モジュールから同期的に呼び出される．メッセージ配列の送受信は可能だが，複数イベントのレース機構はない． |
| FreeBSD に生体認証／fprintd のサポートはあるか | ports 経由でのみ提供される．`security/fprintd` が `fprintd` デーモンおよび `pam_fprintd.so` を提供し，バックエンドに `security/libfprint` を用いる．base システムには含まれず，PAM スタック内で逐次実行される． |
| OpenBSD は PAM を使うか | base システムでは不採用．BSD Authentication を使用する．OpenPAM はサードパーティ製ソフトウェア向けの ports としてのみ提供される． |
| OpenBSD はなぜ PAM を拒否したか | 共有ライブラリ（PAM モジュール）が特権プロセスのアドレス空間へ `dlopen` され隔離境界を持たない点，設定構文の複雑性，および BSD Auth が `pledge` による特権分離ヘルパプロセスを提供できる点を理由とする． |
| BSD Auth はどう動作するか | `auth_call()` が `/usr/libexec/auth/login_<style>` を fork/exec し，fd 3 の socketpair 経由で IPC を行う．ヘルパは行指向の `BI_*` トークンを出力し，親プロセスは `waitpid()` で同期ブロックして応答を解析する． |
| BSD Auth は逐次か並行か | 同期・逐次である．`login_getstyle()` は単一スタイルのみを返し，`auth_verify()` は単一ヘルパを実行し，`auth_call()` がブロック待機する．challenge/response も 2 フェーズの直列通信である． |
| BSD Auth は生体認証とパスワードを並行に待ち受けられるか | 不可能である．複数スタイルを競合させる API はなく，生体認証スタイルのヘルパも同梱されていない．独自ヘルパ内部で並行処理を実装した場合でも，フレームワーク側からは単一のブロッキング子プロセスとして扱われる． |
| NetBSD の生体認証は | pkgsrc の `security/libfprint` のみ提供され，`fprintd` デーモンは存在しない．base システムは OpenPAM を採用する． |
| 縦統合があるのに並行マルチモーダルなデスクトップ認証が無いのはなぜか | 縦統合の対象がカーネル＋base ユーザランドに限定され，デスクトップ環境を含まないため．認証をオーケストレーションするファーストパーティのデスクトップシェルやディスプレイマネージャが存在せず，生体認証スタックも ports / pkgsrc の管轄となる．また base システムの設計思想自体がサーバ・ヘッドレス・特権最小化に特化している． |

---

## 関連ドキュメント

- [`parallel-auth-architecture.md`](parallel-auth-architecture.md) — Linux における指紋 + パスワード並行待ち受けの可否と，GDM / Noctalia / greetd / polkit / sudo の実装比較
- [`fprintd-triage-notes.md`](fprintd-triage-notes.md) — x1c7 実機での fprintd トリアージ記録
- [`thinkpad-x1c7.md`](../hardware/thinkpad-x1c7.md) — x1c7 の指紋認証・PAM 統合の現状

## 出典

FreeBSD / OpenPAM:

- `freebsd/freebsd-src:contrib/openpam/lib/libpam/openpam_dispatch.c`
  （ディスパッチループ，再帰ガード）— `main` から取得．
- `freebsd/freebsd-src:contrib/openpam/lib/libpam/pam_start.c`
  （ハンドルごとに単一の `PAM_CONV`）．
- `freebsd/freebsd-src:contrib/openpam/doc/man/pam_conv.3`
  （`struct pam_conv`，メッセージ配列による会話）．
- `freebsd/freebsd-src:contrib/openpam/include/security/pam_constants.h`
  （`PAM_INCOMPLETE` が無い）．
- `freebsd/freebsd-src:contrib/openpam/README`.
- FreshPorts `security/fprintd` 1.94.4（`lib/security/pam_fprintd.so`，D-Bus
  デーモン）および `security/libfprint`．

NetBSD:

- `NetBSD/src:trunk:external/bsd/openpam/dist/lib/libpam/openpam_dispatch.c`
  （同一ループ．diff は RCSID と enum キャストのみ）．
- `NetBSD/src:trunk:lib/libpam/`（base の OpenPAM モジュール）．
- pkgsrc には `security/libfprint` があり，`security/fprintd` は無い．

OpenBSD（BSD Authentication）:

- `openbsd/src:master:lib/libc/gen/auth_subr.c`（`$OpenBSD: auth_subr.c,v 1.57
  2026/08/29 17:41:02 daniel Exp $`）— `auth_open`，`auth_call`
  （fork/socketpair/waitpid），`auth_challenge`，`BI_*` 解析．
- `openbsd/src:master:lib/libc/gen/authenticate.c`（`$OpenBSD: authenticate.c,v
  1.30 2026/03/10 04:02:53 deraadt Exp $`）— `auth_usercheck`，`auth_userokay`，
  `auth_userchallenge`，`auth_userresponse`，`auth_verify`，`auth_approval`．
- `openbsd/src:master:lib/libc/gen/login_cap.c`（`$OpenBSD: login_cap.c,v 1.51
  2026/07/29 11:01:02 claudio Exp $`）— `login_getstyle`（単一スタイル）．
- `openbsd/src:master:include/login_cap.h` — `_PATH_AUTHPROG`，
  `LOGIN_DEFSTYLE`/`LOGIN_DEFSERVICE`，`BI_*`．
- `openbsd/src:master:usr.bin/login/login.c`（`$OpenBSD: login.c,v 1.75
  2025/11/27 17:27:22 jca Exp $`）— 試行ごとに 1 回の `auth_verify` とリトライループ．
- `openbsd/src:master:libexec/login_*/` — `login_passwd`，`login_skey`，
  `login_token`，`login_yubikey`，`login_radius`，`login_ldap`，`login_chpass`，
  `login_lchpass`，`login_reject`．例えば `login_passwd.c` とその Makefile
  （`BINMODE=4555`，owner root，group auth）．
- `openbsd/src:master:include/bsd_auth.h` および `lib/libc/hidden/bsd_auth.h`．
- `man.openbsd.org`: `login.conf(5)`（`auth` リスト．先頭値が既定スタイル），
  `auth_subr(3)`，`auth_userokay`/`authenticate(3)`．
- OpenBSD ports の `security/openpam` および `security/libfprint`（`fprintd` は無い）．
- OpenBSD `tech@` スレッド "Cleanup of PAM and other gunk in /usr/sbin/pppd"
  （Marc.info，2015-04-13）および "cleanup pppd auth"（2016-05）— PAM に対する
  プロジェクトの見解．

比較・文脈:

- `linux-pam/linux-pam:libpam/pam_dispatch.c`（`_pam_dispatch_aux` の逐次ループと
  `PAM_INCOMPLETE`）．
- Wikipedia, "BSD Authentication"（OpenBSD 2.9 での採用，プロセス分離による
  特権分離．Provos/Friedl/Honeyman を引用）．
- Niels Provos, Markus Friedl, Peter Honeyman, "Preventing Privilege
  Escalation", USENIX Security 2003.
- lambda.cx, "How BSD Authentication Works"（2021-10-18）— `auth_subr.c` と
  `login_<style>` プロトコルのアーキテクチャ解説．
