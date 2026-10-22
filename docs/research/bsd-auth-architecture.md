# BSD 認証アーキテクチャ：同期か並行か

FreeBSD（OpenPAM），NetBSD（OpenPAM），OpenBSD（BSD Authentication）が，Linux-PAM と同様に同期・逐次的であるのか，あるいは生体認証とパスワードを同時に待ち受ける並行マルチモーダル認証を提供しているのかを，upstream のソースコードと man ページに基づいて調査した結果をまとめる．

**判定（要約）**: 3 系はいずれも厳密に同期・逐次であり，並行マルチモーダル認証のプリミティブを備えていない．FreeBSD / NetBSD が使う OpenPAM のモジュールディスパッチャは，Linux-PAM とアーキテクチャ上同一の「チェーンを 1 モジュールずつ辿る単一スレッドループ」であり，PAM ハンドルごとに conversation コールバックを 1 つだけ持つ．OpenBSD の BSD Authentication はセキュリティモデルが大きく異なる（socketpair 越しの特権分離ヘルパプロセス）が，こちらもスタイルを 1 つだけ選択し，ヘルパ 1 つを `waitpid()` で待つ．FreeBSD の生体認証ログインは ports の `security/fprintd`（`pam_fprintd.so` を含む）としてのみ存在するため，逐次的な PAM パイプラインにそのまま乗る．NetBSD は pkgsrc に `libfprint` のみを持ち，OpenBSD base には生体認証の経路が存在しない．

---

## 概要

- FreeBSD・NetBSD の base は OpenPAM を使う．`openpam_dispatch()` はモジュールチェーンを先頭から 1 つずつ同期的に呼ぶループであり，Linux-PAM と本質的に同じ逐次構造である．会話（プロンプト）は PAM ハンドルごとに 1 つの `pam_conv` コールバックで処理される．
- OpenBSD は PAM を採用せず BSD Authentication（BSD Auth）を使う．PAM の dlopen された共有ライブラリが呼び出しプロセス（suid root の login 等）のアドレス空間で動くことを嫌い，`/usr/libexec/auth/login_<style>` を fork/exec し，socketpair のバックチャネルで IPC する特権分離モデルを採る．ただしこれも逐次であり，1 回の試行につき 1 スタイル・1 ヘルパプロセスで，親は `waitpid()` で待つ．生体認証とパスワードを並行に待つ仕組みは無い．
- 縦統合（vertical integration）は「カーネル＋base ユーザランド」に限られ，デスクトップは ports/pkgsrc の第三者スタックである．Apple/Windows のように OS ベンダが認証 UI まで一貫して所有していないため，並行マルチモーダル認証を駆動する主体が存在しない．

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

観察結果:

- **厳密に逐次**．1 つのモジュールが完了してから次が呼ばれる．スレッドも `select()`/`poll()` によるファンアウトも無く，2 つのモジュールを競争させる機構も無い．
- **再入・並行なし**．`pamh->current != NULL` ガードにより，ディスパッチ進行中のネストした `pam_*` 呼び出しは `PAM_ABORT` で失敗する．1 つの PAM ハンドルは同時に 1 つのディスパッチしか持てない．
- `PAM_REQUISITE`，`PAM_SUFFICIENT`，`PAM_BINDING` の各フラグはループの*順序*と*早期終了*の意味だけを制御し，並行性は導入しない．
- NetBSD の `openpam_dispatch.c` は同一コードである．両ファイルの diff は `__RCSID()` の追加と `(enum openpam_sm_primitives)` キャストのみで，ループ本体はバイト単位で等価（`for (; chain != NULL; chain = chain->next)`）である．

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

したがって Linux と BSD の PAM 実装は，同じ同期・単一コールバックのパイプラインを共有する．注目すべき相違点が 1 つある．Linux-PAM は `PAM_INCOMPLETE` を定義しており，モジュールが状態を保存してアプリケーションへ制御を返し，後で*再開*できる（協調的だが依然 1 つずつの非同期ディスパッチ）．OpenPAM は `PAM_INCOMPLETE` を定義して**いない**（`contrib/openpam/include/security/pam_constants.h` に該当定数が無い）ため，OpenPAM のディスパッチは厳密にブロッキングである．つまり Linux-PAM の方が OpenPAM よりイベント駆動に*多少は*適しているが，どちらもモジュールの並行実行は提供しない．

### 1.4 FreeBSD / NetBSD の生体認証

- **FreeBSD**: port `security/fprintd`（現在 1.94.4）が freedesktop の `fprintd` D-Bus デーモン*と* `lib/security/pam_fprintd.so` を提供し，バックエンドは `security/libfprint` である．Linux と同じ upstream スタックをそのまま移植したもので，FreeBSD base には入っていない．FreeBSD の認証は OpenPAM なので，`pam_fprintd` は PAM スタック内の 1 モジュールにすぎず，`pam_unix`/`pam_ssh` 等と順番に呼ばれる．指紋プロンプトとパスワードプロンプトを競争させるフレームワーク支援は無い．
- **NetBSD**: pkgsrc は `security/libfprint` を提供するが，`security/fprintd` パッケージは**無い**．したがって NetBSD にはパッケージ化された生体認証ログインデーモン／PAM モジュールが存在しない．
- どちらも base で OpenPAM を使う．これらのシステムの OpenSSH は BSD auth ではなく `pam` デバイスを使う．

---

## 2. OpenBSD — BSD Authentication（`bsd_auth(3)`，`login_*`）

### 2.1 OpenBSD が PAM を採用しなかった理由

BSD Authentication は BSD/OS（BSDI）に起源を持ち，FreeBSD へ寄贈され，OpenBSD が 2.9 で採用した．OpenBSD は base システムに PAM を意図的に採用しなかった．文書化されている理由を重要性の高い順に挙げる:

1. **特権アドレス空間内の共有ライブラリ**．PAM モジュールは `dlopen` される動的共有オブジェクトであり，認証を行うプロセス*内部*で動作する．`login`，`su`，`sshd`，`passwd`，`ftpd` では，そのプロセスが setuid/setgid root か，それに準ずる高い特権を持つ．モジュールのバグ・バックドア・メモリ安全性の誤りは，呼び出し元の特権とアドレス空間をそのまま得て実行される．隔離境界が存在しない．この立場の一般的な要約（lambda.cx の記事や Wikipedia を参照）は次のとおりである: "the fact that it's a shared library means that any vulnerability in a poorly vetted authentication module gives attackers direct access to the internals of your application."
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

**注意**: OpenBSD の *ports* ツリーには，PAM を強く要求する第三者ソフトウェアをビルドするため `security/openpam`（および `security/libfprint`）が今も存在する．拒否の対象は base システムであり，port を禁じているわけではない．

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

**生体認証とパスワードを並行に待ち受けられるか？** フレームワーク経由では不可能である．2 つのスタイルを開始して先に成功した方を採用する API は無い．原理的には新しいスタイルヘルパ（例: `login_fprint`）を書き，その内部で指紋リーダーと端末プロンプトを開いて競争させることはできるが:

- OpenBSD base にそのようなヘルパは同梱されていない．
- 親から見れば依然 1 スタイル・1 ブロッキング子プロセスであり，並行性はそのヘルパ内部に閉じる．
- リーダデバイスと `/etc/master.passwd` を読むため，特権を持つ独立プロセスにする必要があり，OpenBSD はそのようなデーモンを追加しない選択をしている．

OpenBSD *ports* には `security/libfprint`（指紋バックエンドライブラリ）があるが，`fprintd` デーモンも PAM/BSD-auth の指紋統合も**無い**ため，パッケージ経由の生体認証ログイン手段も存在しない．

---

## 3. 縦統合のパラドックス

「BSD の縦統合された base 開発なら，並行マルチモーダルなデスクトップ認証が生まれたはず」という前提は，2 種類の縦統合を混同している．BSD プロジェクトは**カーネル＋base ユーザランド**（単一リポジトリ，単一リリースエンジニアリング，単一セキュリティレビュー）では縦統合されているが，**デスクトップ**では縦統合されていない．この区別が，並行マルチモーダル認証の不在を説明する．

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

**パラドックスの結論**: 縦統合された base とは，信頼性とリリース／セキュリティ規律の話であり，ユーザ向け認証体験を所有することではない．3 系すべてでデスクトップとログイン UI が対象外である以上，base の認証フレームワーク（単純さと特権分離のため既に同期・単一コールバック）が並行マルチモーダル認証へ拡張されることはなかった．Apple と Microsoft が実現できたのは経路全体を所有していたからであり，BSD はそれを試みていない．

---

## 4. 調査設問への回答

| 設問 | 回答 |
| --- | --- |
| OpenPAM の `openpam_dispatch()` は Linux-PAM と同じ同期・逐次パイプラインか | はい．モジュールチェーンに対する単一の `for` ループで，1 モジュールずつ実行し，`pamh->current` による再帰ガードを持つ．Linux-PAM だけにある追加機能は `PAM_INCOMPLETE` による再開可能モジュールである． |
| `pam_conv` は Linux-PAM と同じ単一コールバックか | はい．`pam_start` 時に設定される `struct pam_conv` は PAM ハンドルごとに 1 つで，モジュールから同期的に呼ばれる．メッセージの*配列*はまとめられるが並行性は得られない． |
| FreeBSD に生体認証／fprintd のサポートはあるか | あるが port としてである: `security/fprintd` が `fprintd` と `pam_fprintd.so` を提供し，`security/libfprint` がバックエンドである．base には入らず，PAM スタック内で逐次実行される． |
| OpenBSD は PAM を使うか | base では使わない．BSD Authentication を使う．OpenPAM は第三者ソフトウェア向けの port としてのみ存在する． |
| OpenBSD はなぜ PAM を拒否したか | モジュールが特権呼び出し元のアドレス空間へ `dlopen` される（隔離なし）こと，複雑さ・設定ミス，そして BSD Auth が `pledge` 可能な特権分離ヘルパプロセスを提供することによる． |
| BSD Auth はどう動作するか | `auth_call()` が `/usr/libexec/auth/login_<style>` を `fork()`/`execve()` し，fd 3 に `socketpair` を配線する．ヘルパは行指向の `BI_*` トークンを出力し，親は `waitpid()` でブロックして spool を解析する． |
| BSD Auth は逐次か並行か | 逐次である．`login_getstyle()` は 1 スタイルを返し，`auth_verify()` は 1 ヘルパを実行し，`auth_call()` はブロックする．challenge/response も 2 フェーズの直列プロトコルである． |
| BSD Auth は生体認証とパスワードを並行に待ち受けられるか | 不可能である．複数スタイルを競争させるプリミティブは無く，生体認証スタイルのヘルパも同梱されていない．独自ヘルパなら内部で私的に実現できるが，フレームワークから見れば 1 つのブロッキング子プロセスのままである． |
| NetBSD の生体認証は | pkgsrc の `security/libfprint` のみで，`fprintd` は無い．base では OpenPAM を使う． |
| 縦統合があるのに並行マルチモーダルなデスクトップ認証が無いのはなぜか | 縦統合はカーネル＋base を対象とし，デスクトップを含まない．オーケストレーションを行うファーストパーティのデスクトップシェル／ディスプレイマネージャが存在せず，デスクトップと生体認証は third-party の ports である．BSD base の哲学はサーバ・ヘッドレス・セキュリティ最小主義である． |

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
