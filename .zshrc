# .zshrc — セクション構成:
#   補完 / 環境変数 / PATH / 色 / プロンプト / 履歴 / zshオプション /
#   キーバインド / エイリアス / ツール初期化 / 関数 / マシン固有
# セットアップ(symlink作成・ツール導入)は setup.sh が担う。
# XDG_CONFIG_HOME は環境側が設定済みなら上書きしない(未設定でも各ツールが ~/.config を既定採用)。
# secrets・会社固有設定は private リポ(末尾で source)が持つ。

# ── 補完 ──
autoload -Uz compinit
compinit

# ── 環境変数 ──
# nvim があれば nvim、無ければ vim にフォールバック(サーバーには nvim を都度手動導入する運用)
if type nvim >/dev/null 2>&1; then export EDITOR=nvim; else export EDITOR=vim; fi
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
alias gs='git status'
alias gps='git push'
alias gpl='git pull'
alias gl='git log --oneline'
# その他
alias l='ll'
alias ll='ls -Falh --color=auto'
alias grep="GREP_COLORS='mt=1;32' grep --color"
type nvim > /dev/null 2>&1 && alias vi='nvim'
alias env='env | sort'
alias ccsession='~/utils/ccsession/ccsession'
alias vi_edits='vi $(git status -s | awk "{print \$2}")'
alias moove='AWS_PROFILE=moove'

# ── ツール初期化 ──
eval "$(sheldon source)"
eval "$(mise activate zsh)"
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # nvm 本体
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # nvm 補完

# ── 関数 ──
# 関数定義(vi_edit / fhistory / fssm / frds 等)は別ファイルに分離(compinit 後に source)
[ -f "$DOTFILES_DIR/zsh/functions.zsh" ] && source "$DOTFILES_DIR/zsh/functions.zsh"

# ── マシン固有 ──
cd $HOME/work
# secrets / AWS profile / bastion 等は private リポが持つ(存在すれば source)
[ -f "$HOME/dotfiles-private/zshrc.private" ] && source "$HOME/dotfiles-private/zshrc.private"
