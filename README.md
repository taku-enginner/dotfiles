# dotfiles

汎用のシェル/エディタ設定を管理する dotfiles。`setup.sh` 一本でシンボリックリンク作成・ツール導入・private 設定の取得まで行う(冪等・ホスト名非依存)。

## 目次

- [構成](#構成)
- [インストール](#インストール)
- [setup.sh の動作](#setupsh-の動作)
- [管理対象](#管理対象)
- [Claude Code 設定](#claude-code-設定)
- [プロンプト下書きペイン(herdr)](#プロンプト下書きペインherdr)
- [herdr プラグイン](#herdr-プラグイン)
- [リモート herdr の常駐(herdr-mirror)](#リモート-herdr-の常駐herdr-mirror)
- [private リポジトリ](#private-リポジトリ)

## 構成

2 リポジトリ構成:

| リポジトリ | 内容 |
| --- | --- |
| **dotfiles**(public, 本リポ) | 汎用設定。zsh / nvim / git / sheldon / mise。`fssm`・`frds` 等の会社非依存ツールも含む |
| **dotfiles-private**(private) | 業務プロジェクト固有設定(secrets・AWS profile・bastion・作業ディレクトリ等)。`zshrc.private` を `.zshrc` 末尾で source |

`XDG_CONFIG_HOME` は `setup.sh` 実行時に対話選択し `~/.zshenv` に永続化する(`.zshrc` 自体は上書きしない)。

## インストール

前提: `sudo git vim curl zsh` は導入済み。

```
cd && \
git clone https://github.com/taku-enginner/dotfiles.git && \
~/dotfiles/setup.sh
```

`setup.sh` が XDG の選択・symlink 作成・sheldon/mise 導入・private リポの clone(任意)まで行う。

## setup.sh の動作

冪等。何度実行しても安全。

1. `DOTFILES_DIR` をスクリプト自身の位置から自動導出(ホスト名分岐なし)
2. `XDG_CONFIG_HOME` を対話選択(`~/.config` か `~/moove/tak/.config`)し `~/.zshenv` に永続化
3. `~/.local/bin` と `XDG_CONFIG_HOME` を作成
4. シンボリックリンクを作成(既に正しいリンクなら無音スキップ、別物なら確認のうえ張り替え)
5. sheldon を導入(未導入時・必須)
6. mise を導入(未導入時・確認のうえ)
7. `mise install`(config.toml に基づくツール導入)
8. private リポを HTTPS で clone(未取得時・確認のうえ。失敗しても汎用設定は維持)
9. herdr プラグインの未導入分を一覧表示(導入はしない・[herdr プラグイン](#herdr-プラグイン))

## 管理対象

| リンク元(本リポ) | リンク先 |
| --- | --- |
| `git` `sheldon` `nvim` `mise` | `$XDG_CONFIG_HOME/<同名>` |
| `.zshrc` | `~/.zshrc` |
| `herdr/config.toml` | `$XDG_CONFIG_HOME/herdr/config.toml` |
| `systemd/user/herdr.service` | `~/.config/systemd/user/herdr.service`(XDG 選択に依らず固定) |
| `bin/cc-compose` | `~/.local/bin/cc-compose` |

その他: `~/.zshenv`(XDG の選択を保存)、`~/dotfiles-private/zshrc.private`(`.zshrc` から source)。

## Claude Code 設定

`~/.claude/` は「**会社 baseline ⊕ 個人設定**」を `setup.sh` が組み立てる。会社 baseline を絶対に汚染しないため、個人設定はすべて本リポ(`dotfiles/claude/`)に分離して外部から読み込む。

| ソース | 役割 |
| --- | --- |
| `~/claude`(会社 baseline / 別リポ) | upstream ミラー。**読取専用・一切書き込まない**。CLAUDE.md・settings.json・skills・hooks・memory・statusline.py の baseline |
| `dotfiles/claude/`(本リポ) | 個人設定。`CLAUDE.override.md`・`settings.override.json` |
| `~/work/moovibe/skills`(任意) | 業務スキル。あれば個別 link |

`setup.sh` の組み立て(`setup_claude`):

- **CLAUDE.md**: baseline ＋ `CLAUDE.override.md` を連結して**実ファイル生成**(symlink にすると外部リポのフックが baseline 本体へ追記して汚染しうるため)
- **settings.json**: baseline ⊕ `settings.override.json` を `jq` で**合成生成**(配列=結合／オブジェクト=deep merge／スカラー=後勝ち)。`settings.local.json` は user レベルでは読まれないため生成しない
- **skills / hooks**: `~/.claude/{skills,hooks}` を**実ディレクトリ**にし、baseline と個人の両ソースから**個別 symlink**(丸ごと symlink しない＝どのリポの作業ツリーも汚さない)。herdr 管理 hook は herdr に委ねる

### 入れていないもの(2026-08-02 に撤去)

コンテキスト削減のため、スキル一覧を膨らませていた連携を外した。実測でスキル説明文が計 43KB あり、その 7 割がプラグイン由来だった。

- **プラグイン**: `vercel`(約 35 エントリ / 21KB)と `crit`(9.6KB)を `enabledPlugins` から外し、`extraKnownMarketplaces` と `setup_plugin_marketplaces` の呼び出しも削除。実体は `~/.claude/plugins/` に残っているので `enabledPlugins` に戻せば復活する
- **personal-context 連携**: `commands` の whole-dir symlink(11 コマンド)、`statusLine` の override、`CLAUDE.override.md` の `global_rules.md` import。コマンドとルールは personal-context ディレクトリで作業する時だけ効けば足りる(あちらの `CLAUDE.md` が `global_rules.md` を自前で import している)。`statusLine` は baseline の `statusline.py` に戻した

`~/claude/setup.sh` は実行しない(本 `setup.sh` が組み立てを全部担う)。会社 baseline を更新するときは `~/claude` で `git pull` するだけ。

## プロンプト下書きペイン(herdr)

Claude Code の会話を見ながら nvim でプロンプトを書くための構成。左=Claude Code / 右=nvim の分割で使う。

Claude Code の Ctrl-G(外部エディタ)は**使わない**。claude 自身が外部エディタ起動時に画面をクリアするため、ペインを分割しても左半分が空白になり会話が見えない。代わりに claude を生かしたまま隣に nvim ペインを開き、書いた本文を herdr 経由で claude の入力欄へ送る。

| 操作 | 動作 |
| --- | --- |
| `prefix+i`(herdr) | claude ペインの右に nvim の下書きペインを開く(`cc-compose`)。既に開いていればフォーカスのみ |
| `<leader>cc`(nvim) | バッファ(または選択範囲)を claude の入力欄へ入れる。送信はしない |
| `<leader>cs`(nvim) | 入れたうえで送信(`chat:submit` = `ctrl+f` を送る) |
| `:CcTarget`(nvim) | 送信先の確認。`:CcTarget wE:pJ` で固定、`:CcTarget clear` で解除 |
| `:q`(nvim) | 下書きペインを閉じる |

操作を忘れたら `cc-compose --help`(チートシート)。下書きバッファの winbar にも送信先と主要キーを常時表示する(`→wE:pJ  SPC cc 入力 / SPC cs 送信 / :q 閉じる`、幅が狭いときは送信先のみ)。

- 下書きは `$TMPDIR/cc-prompt-<tab_id>.md` にタブ単位で残る(ペインを閉じても消えない)
- 送信するとどのペインに入れたかを通知する(`→wE:pJ 3行 ~/work/...`)
- 送信先の決定順: ① `:CcTarget` の固定 ② `cc-compose` が渡した分割元(`CC_TARGET_PANE`) ③ レイアウト座標で「自分の左にあって縦に重なる最も近い Claude ペイン」。同じタブに Claude が複数あっても③まで決定的に選ぶ
- 実装: `bin/cc-compose`(ペイン分割)、`nvim/lua/config/herdr.lua`(`:CcSend` / `:CcSubmit`)
- 送信キーを変えるときは `claude/keybindings.json` と `nvim/lua/config/herdr.lua` の `SUBMIT_KEY` を揃える

## herdr プラグイン

herdr **本体**には**プラグインを宣言的に管理する仕組みが無い**。config での宣言・lockfile・sync のいずれも提供されず、[公式ドキュメント](https://herdr.dev/docs/plugins/)の通り導入状態は "global to the current user" = そのマシンのそのユーザーに閉じる。加えて実体とレジストリ(`plugins.json`)は herdr が管理するため追跡できず、「どれを使っているか」がリポジトリに残らない。その穴を **`herdr-lazy`(宣言リスト + lock)** と、それが扱えない分を見る **`setup.sh` の一覧**の二段で埋める。

| `plugin_id` | 指定子 | 管理 | 用途 |
| --- | --- | --- | --- |
| `worktrunk` | `devashish2203/herdr-worktrunk` | list | worktree の切替・作成・削除 |
| `persiyanov.reviewr` | `persiyanov/herdr-reviewr` | list | 差分を横で review してコメントを入力欄へ |
| `gh-pr` | `wyattjoh/herdr-plugin-gh-pr` | list | ブランチの PR ステータスをサイドバーに表示(`gh` 認証が必要) |
| `mirror` | `nikok6/herdr-mirror` | list | リモート herdr をローカルにミラー(SSH 非対話鍵認証が必要) |
| `herdr-lazy` | `natori-hrj/herdr-lazy` | list | プラグイン構成を `plugins.list` で宣言し `plugins.lock` で固定 |
| `dutifuldev.ghzinga` | `osolmaz/ghzinga/plugins/herdr` | setup.sh | PR/Issue を TUI で開く(本体 `gzg` が必要) |

### herdr-lazy

`herdr/plugins.list` に `owner/repo` を並べたものが宣言、`herdr/plugins.lock` が解決済みコミットの記録。置き場所は `.zshrc` の `HERDR_LAZY_LIST` で dotfiles 側に寄せてある(既定はプラグインの config-dir 配下 = リポジトリに残らない)。lock は list の隣に自動生成されるので、この 1 変数で両方が追跡対象になる。

| 操作 | コマンド |
| --- | --- |
| 不足分を入れる / ずれた pin を戻す | `herdr-lazy install` |
| リストに収束させる | `herdr-lazy sync` |
| lock のコミットへ戻す | `herdr-lazy restore` |
| pin なしを最新へ | `herdr-lazy update` |
| 管理ペイン(`prefix+shift+l`) | `herdr-lazy ui` |

- **`herdr-lazy` は PATH に載らない**。実体は herdr のプラグインディレクトリの中で、名前に install ごとのハッシュが入るため symlink 先を固定できない。`zsh/functions.zsh` の同名関数が実体を glob で引いて渡す。本家 README は `herdr plugin list --json` を python で舐める関数を提示しているが、その JSON は `{result:{plugins:[…]}}` 形式で herdr 0.7.5 が返すトップレベル配列と噛み合わないため採らない(herdr CLI の出力仕様に依存しないのは `setup.sh` と同じ方針)
- **`--prune` を打たない限り既存プラグインは消えない**。`sync --prune` はリスト外を削除するので、`ghzinga` を巻き込む。使わない
- リストの書式は `owner/repo` / `owner/repo@v1.2.0` / `owner/repo@9f3c1ab` のみ。**`owner/repo/subdir` は非対応**なので `ghzinga` は載せられず、`setup.sh` の一覧に残してある
- 既定バンドル(`herdr-plus` 等 5 件)を勝手に入れる初回ブートストラップは `HERDR_LAZY_NO_BOOTSTRAP=1`(`.zshrc`)で止めている。入れる物はこちらで決める
- キーバインドは herdr-lazy に自動追記させず `herdr/config.toml` に手書きする。`config.toml` は dotfiles への symlink で、ツールに書かせるとリンクを壊しうるため

`setup.sh` は**未導入分を表示するだけで導入はしない**。理由は ① herdr CLI の引数仕様に依存しない(`list` を読むだけで `install` を打たない。`install` は `-y` を指定子の前に置くと usage エラーになるなど癖がある) ② rust の一時取得や `rm -rf` を `setup.sh` に持ち込まない ③ 「使うときにセットアップする」運用に合う。目的は入れ忘れの検出で、それは表示で足りる。導入は出力をコピペする。

導入済み判定は `plugin_id` の**厳密一致**(`gh-pr`・`worktrunk` は素の id だが `persiyanov.reviewr`・`dutifuldev.ghzinga` は「作者.名前」形式。前方一致では取りこぼす)。`plugin_id` はリポジトリ名と一致しない(`nikok6/herdr-mirror` → `mirror`)ので、追加するときは `herdr plugin list --json` で実測する。なお herdr は 0 件のとき `--json` でも JSON を返さず `No plugins installed.` を出すため、「0 件」と「herdr が応答しない」は終了コードで区別している。

`ghzinga` だけは本体 `gzg` を先に入れる必要がある(プラグインは `gzg` を呼ぶ薄いガワ。配布はソースのみで `cargo install` が唯一の入手経路)。出来たバイナリは Rust std を静的リンクしており実行に rust は不要なので、rust はビルド時だけ借りて捨てられる:

```
mise x rust@latest -- cargo install --root "$HOME/.local" ghzinga
mise uninstall --all rust && rm -rf ~/.cargo/registry   # rust を捨てる場合
```

`--root` を渡すのは、既定の `~/.cargo/bin` を `.zshrc` で PATH に入れていないため。

`$XDG_CONFIG_HOME/herdr` は**実ディレクトリ**にし、`config.toml` だけを個別 symlink する(skills / hooks と同じ方式)。ディレクトリごと symlink にしてはいけない — herdr は config と同じディレクトリに `plugins.json` とプラグイン実体を書くため、① 公開リポの作業ツリーに実体が落ちる ② 追跡外にすると新マシンで実体が無い ③ `setup.sh` 再実行時に `create_symlink` が実ディレクトリを `rm -rf` してプラグインが全消えする、を招く(2026-07-30 に③で実際に消失させた)。

`mirror` の対象ホストは `~/.config/herdr/plugins/config/mirror/hosts.toml` で定義する(公開リポなので追跡しない)。`herdr/config.toml` に `mirror.*` のキーバインドを割り当て済み。
## リモート herdr の常駐(herdr-mirror)

`herdr-mirror` プラグインがリモート(`tak.moove.bz`)の workspace/agent をローカルのサイドバーへミラーする。前提は「**リモートで herdr server が動いていること**」の一点で、ここが落ちると `prefix+alt+n`(リモートに workspace を作る)などのリモート系キーが軒並み無反応になる。

リモートには誰も ssh していない時間帯があり、リブートすればサーバは消える。手動起動に頼らないよう systemd user service で常駐させる。

```bash
# リモート機で一度だけ(setup.sh の該当プロンプトに y と答えるのと同じ)
mkdir -p ~/.config/systemd/user
ln -s ~/dotfiles/systemd/user/herdr.service ~/.config/systemd/user/herdr.service
loginctl enable-linger "$USER"     # 無いとログアウトで user manager ごと落ちる
systemctl --user enable --now herdr.service
```

- unit は `zsh -lc 'exec herdr server'` で起動する。systemd の user manager は `~/.zshenv` を読まないため、直接 `herdr server` を叩くと `XDG_CONFIG_HOME` を見失い、ペインのシェルも `~/.local/bin` を含まない PATH になる
- unit の置き場は `$XDG_CONFIG_HOME` ではなく **`~/.config/systemd/user` 固定**(user manager は PAM 経由で起動するので `~/.zshenv` の XDG 選択が届かない)
- ローカル(WSL)では herdr を対話起動しているので有効化しない。両方立てると server が二重になる
- `systemctl --user disable` は symlink 本体まで消す。戻すには `setup.sh` を再実行する

リモート系のキーが効かないときの切り分け:

| 見るもの | 正常なら |
| --- | --- |
| ローカル `tail ~/.local/state/herdr-mirror/daemon.log` | `disconnected (remote herdr server is not running)` が出ていない |
| リモート `herdr status` | `server: running` |
| リモート `systemctl --user status herdr` | `active (running)` |
| リモート `loginctl show-user "$USER" \| grep Linger` | `Linger=yes` |

## private リポジトリ

`taku-enginner/dotfiles-private` を `~/dotfiles-private` に clone して連携する。
業務プロジェクト固有設定(secrets・AWS profile・bastion・作業ディレクトリ等)を保持し、`.zshrc` 末尾で `~/dotfiles-private/zshrc.private` を source する(存在しなければスキップ)。
