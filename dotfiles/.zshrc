autoload -Uz compinit
compinit
set -g mouse on

# color
autoload -Uz colors
colors
local BLACK=$'%{\e[90m%}'
local RED=$'%{\e[91m%}'
local GREEN=$'%{\e[92m%}'
local YELLOW=$'%{\e[93m%}'
local BLUE=$'%{\e[94m%}'
local PURPLE=$'%{\e[95m%}'
local CYAN=$'%{\e[96m%}'
local WHITE=$'%{\e[39\m%}'
local CLEAR=$'%{\e[0m%}'

export EDITOR=nvim
export PATH="/opt/homebrew/bin:$PATH"
export APPLE_ID="taku112ne@gmail.com"
export APP_SPECIFIC_PASSWORD="bavl-tykx-abwp-wash"
export NTFY_TOPIC="aikakeibo-taku-2024"

confirm_exe() {
  echo -n "$1 (y/N) --> "
  read -r yn
  case $yn in
  y | Y)
    echo '実行します...'
    return 0
    ;;
  *)
    echo '中止しました'
    return 1
    ;;
  esac
}

create_symlink() {
  if [ ! -e "$1" ]; then
    echo "リンク先が存在しません: $1"
  elif [ -e "$2" ]; then
    echo "同名のファイルが既に存在します: $2"
    confirm_exe "このファイルを削除してシンボリックリンクを作成しますか?" && rm "$2" && ln -s "$1" "$2" && echo "シンボリックリンクを作成しました: $2 -> $1"
  else
    ln -s "$1" "$2"
    echo "シンボリックリンクを作成しました: $2 -> $1"
  fi
}

install_sheldon() {
  curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to $HOME/moove/tak/.local/bin &&
  $HOME/moove/tak/.local/bin/sheldon init --shell zsh
}
type $HOME/moove/tak/.local/bin/sheldon >/dev/null || install_sheldon


if [ "$HOST" = 'takakusakitakushinnoMacBook-Air.local' -o "$HOST" = 'tak.moove.bz' -o "$HOST" = 'LAPTOP-0Q4P8DSR' -o "$SLEDGE_CONFIG" = 'development' ]; then
  source "$HOME/moove/tak/dotfiles/.zshrc.local"
else #プロジェクトサーバーの場合
  source "$HOME/moove/tak/dotfiles/.zshrc.project"
fi

eval "$(sheldon source)"
eval "$(mise activate zsh)"

# メモリに保存する履歴の件数
HISTSIZE=10000
# 履ファイル(~/.zsh_hmstory)に保存する件数
SAVEHIST=10000
# 履歴共有・即時保存設定
HISTFILE=$HOME/moove/tak/.zsh_history

# alias
alias al='alias | sort'
alias git-ignore-ls="echo '=== Ignored Files ===' && git ls-files --others --ignored --exclude-standard ./"
alias ga='git add'
alias gb='git branch'
alias gc='git commit'
alias gd='git diff'
alias gs='git st'
alias gps='git push'
alias gpl='git pull'
alias gl='git log --oneline'
alias gr='git remote'
alias l='ls -Fal --color=auto'
alias ll='ls -Fal --color=auto'
alias grep="GREP_COLORS='mt=1;32' grep --color"
type nvim > /dev/null && alias vi="nvim"
alias env='env | sort'

# TOMOS
#alias ddiu='docker compose down app web && docker image rm tomos-app && docker compose up -d && docker compose exec -it app tail -n +1 -F /var/log/api_koshida.log'

# history
function fhistory() {
  BUFFER=$(history -n -r 1 | fzf --reverse --no-sort +m --query "$LBUFFER" --prompt="History > ")
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fhistory
bindkey '^r' fhistory

# lang
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8

setopt share_history      # 他のzshセッションと履歴を共有
setopt inc_append_history # コマンド実行後すぐに履歴ファイルに書き込む
setopt extended_history   # 実行時刻なども記録
setopt hist_ignore_dups   # 同じコマンドの重複を記録しない
setopt hist_reduce_blanks # 余計な空白を除去して記録
setopt auto_cd            # ディレクトリ名だけでcdコマンドを実行
setopt correct            # コマンドのスペルミスを補正

# キーバインド
bindkey '^W' forward-word      # 単語ごとに前に移動する
bindkey '^B' backward-word     # 単語ごとに後ろに移動する
bindkey '^D' kill-word         # 単語ごとに削除する
bindkey '^A' beginning-of-line # 頭行に移動する
bindkey '^E' end-of-line       # 行末に移動する
bindkey '^K' kill-line         # カーソルから行末まで削除


eval "$(rbenv init -)"
cd $HOME

export NVM_DIR="$HOME/moove/tak/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
