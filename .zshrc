# .zshrc — セクション構成:
#   補完 / 環境変数 / PATH / 色 / プロンプト / 履歴 / zshオプション /
#   キーバインド / エイリアス / ツール初期化 / エディタ / 関数 / マシン固有
# セットアップ(symlink作成・ツール導入)は setup.sh が担う。
# XDG_CONFIG_HOME は環境側が設定済みなら上書きしない(未設定でも各ツールが ~/.config を既定採用)。
# secrets・会社固有設定は private リポ(末尾で source)が持つ。

# ── 補完 ──
autoload -Uz compinit
compinit

# ── 環境変数 ──
# EDITOR と alias vi は nvim が mise 管理のため「エディタ」セクション(mise activate 後)で設定する
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
export USER=$(whoami)

# ── PATH ──
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/local/bin:$PATH"

# この .zshrc の実体があるディレクトリ(symlink を解決して導出)
DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${(%):-%x}")")" && pwd)"

# WSL interop が追加する Windows 側 PATH(/mnt/c/...)を除外する。
# drvfs の stat が遅く、zsh-syntax-highlighting のキーストローク毎の
# コマンド検索で約180ms/打のラグが出るため。Windows 製ツールは下の alias で個別に残す。
path=(${path:#/mnt/c/*})
typeset -U path
[[ -e "/mnt/c/Users/taku1/AppData/Local/Programs/Microsoft VS Code/bin/code" ]] && \
  alias code="/mnt/c/Users/taku1/AppData/Local/Programs/Microsoft\ VS\ Code/bin/code"
[[ -e "/mnt/c/Users/taku1/AppData/Local/Programs/cursor/resources/app/bin/cursor" ]] && \
  alias cursor="/mnt/c/Users/taku1/AppData/Local/Programs/cursor/resources/app/bin/cursor"

# ── 色 ──
autoload -Uz colors
colors
local BLACK=$'%{\e[90m%}'
local RED=$'%{\e[91m%}'
local GREEN=$'%{\e[92m%}'
local YELLOW=$'%{\e[93m%}'
local BLUE=$'%{\e[94m%}'
local PURPLE=$'%{\e[95m%}'
local CYAN=$'%{\e[96m%}'
local WHITE=$'%{\e[39m%}'
local CLEAR=$'%{\e[0m%}'

# ── プロンプト ──
# テンプレートが無ければコピーして source(prompt は色変数を利用するため色定義の後)
[[ ! -e $DOTFILES_DIR/.zshrc.prompt ]] && cp $DOTFILES_DIR/.zshrc.prompt_template $DOTFILES_DIR/.zshrc.prompt
[[ -e $DOTFILES_DIR/.zshrc.prompt ]] && source $DOTFILES_DIR/.zshrc.prompt

# ── 履歴 ──
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000            # メモリに保持する件数
SAVEHIST=100000           # 履歴ファイルに保存する件数
setopt share_history      # 他のzshセッションと履歴を共有
setopt inc_append_history # コマンド実行後すぐに履歴ファイルに書き込む
setopt extended_history   # 実行時刻なども記録
setopt hist_ignore_dups   # 同じコマンドの重複を記録しない
setopt hist_reduce_blanks # 余計な空白を除去して記録
# 履歴ファイルの権限補正(読み書き不可なら 600 に戻す)
if [ -f "$HISTFILE" ] && [ ! -r "$HISTFILE" ] && [ ! -w "$HISTFILE" ]; then
  sudo chmod 600 "$HISTFILE"
fi

# ── zsh オプション ──
setopt auto_cd            # ディレクトリ名だけでcdコマンドを実行
setopt correct            # コマンドのスペルミスを補正

# ── キーバインド ──
bindkey '^W' forward-word      # 単語ごとに前に移動する
bindkey '^B' backward-word     # 単語ごとに後ろに移動する
bindkey '^D' kill-word         # 単語ごとに削除する
bindkey '^A' beginning-of-line # 頭行に移動する
bindkey '^E' end-of-line       # 行末に移動する
bindkey '^K' kill-line         # カーソルから行末まで削除

# ── エイリアス ──
# git
alias git-ignore-ls="echo '=== Ignored Files ===' && git ls-files --others --ignored --exclude-standard ./"
alias ga='git add'
alias gb='git branch'
alias gc='git commit'
alias gd='git diff'
alias gs='git status --short --branch'
alias gps='git push'
alias gpl='git pull'
alias gl='git log --oneline'
# その他
alias l='ll'
alias ll='ls -Falh --color=auto'
alias grep="GREP_COLORS='mt=1;32' grep --color"
alias env='env | sort'
alias ccsession='~/utils/ccsession/ccsession'
alias vi_edits='vi $(git status -s | awk "{print \$2}")'
alias moove='AWS_PROFILE=moove'
alias leaf='leaf --watch'

# ── ツール初期化 ──
eval "$(sheldon source)"
eval "$(mise activate zsh)"
if type fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
  export FZF_CTRL_R_OPTS='--prompt="History > "'
fi
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # nvm 本体
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # nvm 補完

# herdr-lazy: herdr のプラグイン構成を plugins.list(宣言)+ plugins.lock(コミット固定)で管理する。
# 既定では list をプラグインの config-dir に置く = リポジトリに残らないため、dotfiles 側へ逃がす。
# lock は list の隣に自動生成されるので、この 1 変数で両方が追跡対象になる。
# NO_BOOTSTRAP: 「list が無く herdr-lazy 以外未導入」のマシンで既定バンドル 5 件を勝手に入れる
# 初回ブートストラップを止める。導入済みの環境では発動しないが、新マシンで setup.sh より先に
# herdr が起動すると条件を満たしうるため明示的に殺しておく(入れる物はこちらで決める)。
export HERDR_LAZY_LIST="$DOTFILES_DIR/herdr/plugins.list"
export HERDR_LAZY_NO_BOOTSTRAP=1

# ── エディタ ──
# nvim は mise 管理のため、mise activate で PATH が通った後でないと type で検出できない。
# このブロックをツール初期化より前に置くと必ず vim へ落ちるので順序を動かさないこと。
# nvim が無い環境(未 mise install のサーバー等)では vim にフォールバックする。
if type nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  alias vi='nvim'
else
  export EDITOR=vim
fi

# ── 関数 ──
# 関数定義(vi_edit / fssm / frds 等)は別ファイルに分離(compinit 後に source)
[ -f "$DOTFILES_DIR/zsh/functions.zsh" ] && source "$DOTFILES_DIR/zsh/functions.zsh"

# ── マシン固有 ──
cd $HOME/work
# secrets / AWS profile / bastion 等は private リポが持つ(存在すれば source)
[ -f "$HOME/dotfiles-private/zshrc.private" ] && source "$HOME/dotfiles-private/zshrc.private"

# 3台共有の API キー。vault の .env.shared だけを追跡対象にしてある(vault/.gitignore)。
# .env 本体は source しない — Mattermost のトークンまで全プロセスの環境変数に出るため、
# 必要なキーだけを個別に拾う。grep 1回なので起動時間にはほぼ効かない。
if [ -f "$HOME/vault/.env.shared" ]; then
  export TYPESAFE_API_KEY="${$(grep -m1 '^TYPESAFE_API_KEY=' "$HOME/vault/.env.shared")#*=}"
  # はてなブックマーク API(OAuth 1.0a)。読了した記事の「あとで読む」タグを外すのに使う。
  # consumer は開発者ページで発行、access は oauth_setup_hatena.py の初回実行で取る。
  # 4つとも揃わないと API を叩けないが、無くてもシェルは起動する(空で export される)。
  export HATENA_CONSUMER_KEY="${$(grep -m1 '^HATENA_CONSUMER_KEY=' "$HOME/vault/.env.shared")#*=}"
  export HATENA_CONSUMER_SECRET="${$(grep -m1 '^HATENA_CONSUMER_SECRET=' "$HOME/vault/.env.shared")#*=}"
  export HATENA_ACCESS_TOKEN="${$(grep -m1 '^HATENA_ACCESS_TOKEN=' "$HOME/vault/.env.shared")#*=}"
  export HATENA_ACCESS_SECRET="${$(grep -m1 '^HATENA_ACCESS_SECRET=' "$HOME/vault/.env.shared")#*=}"
  # fast-jev-compaction(Claude Code プラグイン)が要求する function hooks の有効化。
  # 秘密ではないが、settings.json は setup.sh が再生成するうえ dotfiles/claude/ は
  # 公開リポジトリなので、キーと同じくここで環境変数として渡す。
  export CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1
  # jev-router の Long tier(Fable)。既定で無効なので、立てないと jev-claude 起動時に
  # Fable が一度も選ばれず、global_rules の「計画も実装も Fable 5」が黙って外れる。
  export JEV_ALLOW_FABLE=1
fi

# zsh のコマンド補完を Jev に出す(fish 風のグレー表示)。キーワード一致ではなく
# 履歴100件から「何を打とうとしているか」を判定させる。
# ⚠️ 1キーストロークにつき API 1リクエスト。従量課金なので、常用する前に使用量を見ること。
# [[ -f ]] で囲うのは必須 — .zshrc は3台共有なので、clone していないマシンでは
# 黙って飛ばさないと毎回シェル起動時にエラーが出る(herdr-agent-state.sh と同じ穴)。
if [ -f "$HOME/.zsh/jev-shell-history/zsh/jev-shell-history.plugin.zsh" ]; then
  source "$HOME/.zsh/jev-shell-history/zsh/jev-shell-history.plugin.zsh"
fi

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
