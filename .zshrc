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
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/local/bin:$PATH"
export USER=$(whoami)

install_sheldon() {
  curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to $HOME/moove/tak/.local/bin &&
  $HOME/moove/tak/.local/bin/sheldon init --shell zsh
}
type $HOME/moove/tak/.local/bin/sheldon >/dev/null || install_sheldon

install_mise() {
  cd "$HOME/moove/tak" && ([ -e "$HOME/moove/tak/.local/bin/mise" ] || curl https://mise.run | sh)
}

export XDG_CONFIG_HOME='/home/tak/.config'
# config dir
[ -d "$XDG_CONFIG_HOME" ] || mkdir -p "$XDG_CONFIG_HOME"

# symlinks
[ -L "$XDG_CONFIG_HOME/git" ]     || ln -s "$HOME/dotfiles/git"     "$XDG_CONFIG_HOME/git"
[ -L "$XDG_CONFIG_HOME/sheldon" ] || ln -s "$HOME/dotfiles/sheldon" "$XDG_CONFIG_HOME/sheldon"
[ -L "$XDG_CONFIG_HOME/nvim" ]    || ln -s "$HOME/dotfiles/nvim"    "$XDG_CONFIG_HOME/nvim"

if [ "$HOST" = 'tak.moove.bz' ] || [ "$HOST" = 'LAPTOP-0Q4P8DSR' ]; then
  [ -L "$XDG_CONFIG_HOME/mise" ] || ln -s "$HOME/dotfiles/mise" "$XDG_CONFIG_HOME/mise"
fi

# mise install
if ! command -v mise >/dev/null; then
  install_mise
fi

# mise packages
if command -v mise >/dev/null; then
  mise install
fi

# zshのコマンド履歴を見れるようにする
ZSH_HISTORY_PATH="$HOME/moove/tak/.zsh_history"
if [ -f "$ZSH_HISTORY_PATH" ]; then
  if [ ! -r "$ZSH_HISTORY_PATH" -a ! -w "$ZSH_HISTORY_PATH" ]; then
    sudo chmod 755 "$ZSH_HISTORY_PATH"
  fi
fi

# プロンプトテンプレートがあればそれを使ってなかったらコピー
[[ ! -e $HOME/dotfiles/.zshrc.prompt ]] && cp $HOME/dotfiles/.zshrc.prompt_template $HOME/dotfiles/.zshrc.prompt
[[ -e $HOME/dotfiles/.zshrc.prompt ]] && source $HOME/dotfiles/.zshrc.prompt

alias tm='tmux'
alias dc='docker compose'
alias dp='docker ps'
alias ds='docker stop'
alias docker_images_sort_repository='docker images | tail -n +2 | sort -k1'
alias docker_rm_none_images='docker rmi $(docker images -f "dangling=true" -q)'
alias share_dotfiles='cp -r ~/moove/tak/* ~/taku-enginner/'

if ! command -v hw > /dev/null; then
  mkdir -p $HOME/local/tmp
  cd ${HOME}/local/tmp && git clone https://github.com/tkengo/highway.git && cd highway && ./tools/build.sh && mv hw ${HOME}/local/bin
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
alias vi='nvim'
type nvim > /dev/null && alias vi="nvim"
alias env='env | sort'

#複雑なコマンドはエイリアスではなく関数で扱う
vi_edit() {
  gs | grep '^[ M]' | awk '{print $2}' | xargs nvim
}

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

export NVM_DIR="$HOME/moove/tak/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

cd $HOME
