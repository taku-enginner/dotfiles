# dotfiles

汎用のシェル/エディタ設定を管理する dotfiles。`setup.sh` 一本でシンボリックリンク作成・ツール導入・private 設定の取得まで行う(冪等・ホスト名非依存)。

## 目次

- [構成](#構成)
- [インストール](#インストール)
  - [案件マシン(必要ソフト導入済み)](#案件マシン必要ソフト導入済み)
  - [Ubuntu 空コンテナの場合](#ubuntu-空コンテナの場合)
  - [プロジェクト途中参画の場合](#プロジェクト途中参画の場合)
  - [認証トークンについて](#認証トークンについて)
- [setup.sh の動作](#setupsh-の動作)
- [管理対象](#管理対象)
- [private リポジトリ](#private-リポジトリ)
- [Docker コンテナ操作](#docker-コンテナ操作)

## 構成

2 リポジトリ構成:

| リポジトリ | 内容 |
| --- | --- |
| **dotfiles**(public, 本リポ) | 汎用設定。zsh / tmux / nvim / git / sheldon / mise。`fssm`・`frds` 等の会社非依存ツールも含む |
| **dotfiles-private**(private) | secrets・会社固有設定(AWS profile / bastion / 作業ディレクトリ等)。`zshrc.private` を `.zshrc` 末尾で source |

`XDG_CONFIG_HOME` は `setup.sh` 実行時に対話選択し `~/.zshenv` に永続化する(`.zshrc` 自体は上書きしない)。

## インストール

### 案件マシン(必要ソフト導入済み)

前提: `sudo git vim curl zsh` は導入済み。

```
cd && \
git clone https://github.com/taku-enginner/dotfiles.git && \
~/dotfiles/setup.sh
```

`setup.sh` が XDG の選択・symlink 作成・sheldon/mise 導入・private リポの clone(任意)まで行う。

### Ubuntu 空コンテナの場合

必要ソフトの導入 → ユーザー追加 → パスワード設定:

```
apt update && \
apt install sudo git vim curl zsh -y && \
useradd -m tak -s /usr/bin/zsh && \
passwd tak && \
cp /etc/sudoers /etc/backup_sudoers && visudo && \
su tak
```

visudo で以下を追記:

```
tak ALL=(ALL) ALL
```

clone → `setup.sh` 実行 → シェル再読込:

```
cd && \
git clone https://github.com/taku-enginner/dotfiles.git && \
~/dotfiles/setup.sh && \
exec zsh
```

mise のツールが未導入なら `mise trust` のうえ `~/dotfiles/setup.sh` を再実行する。

### プロジェクト途中参画の場合

clone あたりから上記と同様に実行する。

### 認証トークンについて

HTTPS clone 時に「パスワードが廃止された」と表示される場合は Personal Access Token を使う。
GitHub の Settings → Developer settings → Personal access tokens → Tokens(classic) で発行し、パスワード欄に入力する。
private リポの clone でも同様にトークンを使用する。

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

## 管理対象

| リンク元(本リポ) | リンク先 |
| --- | --- |
| `tmux` `git` `sheldon` `nvim` `mise` | `$XDG_CONFIG_HOME/<同名>` |
| `.zshrc` | `~/.zshrc` |

その他: `~/.zshenv`(XDG の選択を保存)、`~/dotfiles-private/zshrc.private`(`.zshrc` から source)。

## private リポジトリ

`taku-enginner/dotfiles-private` を `~/dotfiles-private` に clone して連携する。
secrets・会社固有設定を保持し、`.zshrc` 末尾で `~/dotfiles-private/zshrc.private` を source する(存在しなければスキップ)。

## Docker コンテナ操作

コンテナ立ち上げ:

```
docker run -it ubuntu
```

コンテナに再度入る:

```
docker start コンテナID
docker container exec -it コンテナID bash
```

ubuntu コンテナをすべて削除する(※注意!):

```
docker stop $(docker ps -a --filter "ancestor=ubuntu" --format "{{.ID}}")
docker rm $(docker ps -a --filter "ancestor=ubuntu" --format "{{.ID}}")
```
