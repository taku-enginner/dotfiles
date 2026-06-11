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
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/local/bin:$PATH"
export USER=$(whoami)

# この .zshrc の実体があるディレクトリ(symlink を解決して導出)
DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${(%):-%x}")")" && pwd)"

# セットアップ(symlink作成・ツールインストール)は setup.sh が担う。
# XDG_CONFIG_HOME は環境側が設定済みの場合がある(上書き禁止)。未設定でも
# 各ツールが ~/.config を既定採用するため、ここでは設定しない。
# secrets・会社固有設定は private リポ(末尾で source)が持つ。

# zshのコマンド履歴ファイルの権限補正
ZSH_HISTORY_PATH="$HOME/.zsh_history"
if [ -f "$ZSH_HISTORY_PATH" ]; then
  if [ ! -r "$ZSH_HISTORY_PATH" -a ! -w "$ZSH_HISTORY_PATH" ]; then
    sudo chmod 755 "$ZSH_HISTORY_PATH"
  fi
fi

# プロンプトテンプレートがあればそれを使ってなかったらコピー
[[ ! -e $DOTFILES_DIR/.zshrc.prompt ]] && cp $DOTFILES_DIR/.zshrc.prompt_template $DOTFILES_DIR/.zshrc.prompt
[[ -e $DOTFILES_DIR/.zshrc.prompt ]] && source $DOTFILES_DIR/.zshrc.prompt

alias tm='tmux'
alias dc='docker compose'
alias dp='docker ps'
alias ds='docker stop'
alias docker_images_sort_repository='docker images | tail -n +2 | sort -k1'
alias docker_rm_none_images='docker rmi $(docker images -f "dangling=true" -q)'

if ! command -v hw > /dev/null; then
  mkdir -p $HOME/local/tmp
  cd ${HOME}/local/tmp && git clone https://github.com/tkengo/highway.git && cd highway && ./tools/build.sh && mv hw ${HOME}/local/bin
fi

eval "$(sheldon source)"
eval "$(mise activate zsh)"

# メモリに保存する履歴の件数
HISTSIZE=10000
# 履歴ファイル(~/.zsh_history)に保存する件数
SAVEHIST=100000
# 履歴共有・即時保存設定
HISTFILE=$HOME/.zsh_history

# alias
alias git-ignore-ls="echo '=== Ignored Files ===' && git ls-files --others --ignored --exclude-standard ./"
alias ga='git add'
alias gb='git branch'
alias gc='git commit'
alias gd='git diff'
alias gs='git st'
alias gps='git push'
alias gpl='git pull'
alias gplo='git pull origin main'
alias gl='git log --oneline'
alias gr='git remote'
alias al='alias | sort'
alias l='ll'
alias ll='ls -Falh --color=auto'
alias grep="GREP_COLORS='mt=1;32' grep --color"
alias vi='nvim'
type nvim > /dev/null && alias vi="nvim"
alias env='env | sort'
alias ccsession='~/utils/ccsession/ccsession'
alias sni_perl="vi $DOTFILES_DIR/nvim/snippets/perl.json"
alias sni_md="vi $DOTFILES_DIR/nvim/snippets/md.json"
alias vi_edits='vi $(git status -s | awk "{print \$2}")'
alias moove='AWS_PROFILE=moove'

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

export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# === AWS 汎用ツール(会社非依存) ===
# fssm: fzf で実行中の EC2 / ECS を選んで SSM 接続する
_fssm_completions() {
  _arguments '1: :->subcommand'
  case "$state" in
    subcommand)
      _values $state \
        'ec2[EC2]' \
        'ecs[ECS]'
      ;;
  esac
}
compdef _fssm_completions fssm

function fssm() {
  case "$1" in
    ec2)
      local target_line=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --query "Reservations[].Instances[].{Id:InstanceId, Name:Tags[?Key=='Name'].Value|[0], IP:PrivateIpAddress, AZ:Placement.AvailabilityZone}" \
        --output json | \
        jq -r '.[] | [.Id, (.Name // "<No Name>"), .IP, .AZ] | @tsv' | \
        sort -k2 | \
        column -t -s $'\t' | \
        fzf --prompt="Select EC2 Instance (ECS or Ctrl+C to cancel)> " --header="Instance ID | Name | Private IP | AZ")
      [ -z "$target_line" ] && return 1

      local instance_id=$(echo "$target_line" | awk '{print $1}')
      local instance_name=$(echo "$target_line" | awk '{print $2}')
      echo "Connecting to..."
      echo "Instance ID: $instance_id"
      echo "Name:        $instance_name"
      echo "----------------------------------------"
      aws ssm start-session --target "$instance_id"
      ;;
    ecs)
      local cluster=$(aws ecs list-clusters --query 'clusterArns[]' --output text | \
        tr '\t' '\n' | \
        awk -F/ '{print $NF}' | \
        sort | \
        fzf --prompt="Select Cluster (ESC or Ctrl+C to cancel)> " --header="Cluster Name")

      [ -z "$cluster" ] && return 1

      local task_arns=$(aws ecs list-tasks --cluster "$cluster" --desired-status RUNNING --query 'taskArns[]' --output text)
      if [ -z "$task_arns" ]; then
        echo "No running tasks found in cluster: $cluster" >&2
        return 1
      fi

      local target_line=$(echo "$task_arns" | xargs -n 100 aws ecs describe-tasks --cluster "$cluster" --output json --tasks | \
        jq -r '.tasks[] | .taskArn as $arn | .group as $group | .containers[] | [$group, ($arn | split("/") | last), .name, .runtimeId] | @tsv' | \
        column -t -s $'\t' | \
        fzf --prompt="Select Container (ECS or Ctrl+C to cancel)> " \
        --header="Service/Group | Task ID | Container Name | Runtime ID")

      [ -z "$target_line" ] && return 1

      local task_id=$(echo "$target_line" | awk '{print $2}')
      local container_name=$(echo "$target_line" | awk '{print $3}')
      echo "Connecting to..."
      echo "Cluster:   $cluster"
      echo "Task:      $task_id"
      echo "Container: $container_name"
      echo "----------------------------------------"
      aws ecs execute-command --cluster "$cluster" --task "$task_id" --container "$container_name" --command "/bin/sh" --interactive
      ;;
    *)
      echo "Usage: fssm <ec2|ecs>"
      return 1
      ;;
  esac
}

# frds: fzf で Aurora を選んで bastion 経由のポートフォワード + mysql 接続する。
# bastion 名は ${BASTION_PREFIX}-<env>-bastion (BASTION_PREFIX は private 側で設定)
function frds() {
  local bastion_name="${BASTION_PREFIX:-toro}-$1-bastion"
  local selected_line=$(aws rds describe-db-clusters \
    --query "DBClusters[].{ID:DBClusterIdentifier, Host:Endpoint, Port:Port, Arn:MasterUserSecret.SecretArn}" \
    --output json | \
    jq -r '.[] | "\(.ID)\t\(.Host)\t\(.Port)\t\(.Arn)"' | \
    column -t -s $'\t' | \
    fzf --prompt="Aurora Cluster を選択してください (ECS or Ctrl+C to cancel)> ")
  [ -z "$selected_line" ] && return 0

  local db_host=$(echo "$selected_line" | awk '{print $2}')
  local db_port=$(echo "$selected_line" | awk '{print $3}')
  local secret_arn=$(echo "$selected_line" | awk '{print $4}')
  if [[ "$secret_arn" == "null" ]] || [[ -z "$secret_arn" ]]; then
    echo "エラー: この Cluster に紐付けられた Secret Manager がありません" >&2
    return 1
  fi

  echo "紐付けられた Secret Manager から認証情報を取得中..."
  local secret_json=$(aws secretsmanager get-secret-value --secret-id "$secret_arn" --query SecretString --output text)
  local db_user=$(echo "$secret_json" | jq -r '.username')
  local db_pass=$(echo "$secret_json" | jq -r '.password')

  local local_port=$((10000 + RANDOM % 50000))
  echo "$bastion_name 経由で接続中：$db_host:$db_port -> localhost:$local_port"
  local bastion_id=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${bastion_name}" "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)
  set +m
  aws ssm start-session --target "$bastion_id" \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{\"host\":[\"$db_host\"],\"portNumber\":[\"$db_port\"], \"localPortNumber\":[\"$local_port\"]}" > /dev/null 2>&1 &
  local ssm_pid=$!
  set -m
  trap "kill $ssm_pid 2>/dev/null" EXIT
  sleep 2

  MYSQL_PWD="$db_pass" mysql -h 127.0.0.1 -P "$local_port" -u "$db_user"
}

cd $HOME

# マシン固有・会社固有設定(secrets / AWS profile / bastion 等)は private リポが持つ
[ -f "$HOME/dotfiles-private/zshrc.private" ] && source "$HOME/dotfiles-private/zshrc.private"
