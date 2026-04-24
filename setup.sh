#!//usr/bin/zsh

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

#create_dotfiles() {
  #cd $home

  #if [ ! -d "$XDG_CONFIG_HOME" ]; then
    #mkdir "$XDG_CONFIG_HOME"
    #echo "Created enpty dir: $XDG_CONFIG_HOME"
  #fi
#}

#copy_ssh_config() {
  #cd $home
  #[ ! -d .ssh ] && mkdir .ssh
  #confirm_exe '.ssh/config をコピーしますか?' && cp settings/dotfiles/ssh/config $home/.ssh/config
#}

install_mise() {
  cd $home && ([ -e $home/.local/bin/mise ] || curl https://mise.run | sh)
}

#confirm_exe 'dotfiles を作成しますか?' && create_dotfiles

echo "現在のホスト名: $HOST"
if [ "$HOST" = 'tak.moove.bz' ] || [ "$HOST" = 'LAPTOP-0Q4P8DSR' ]; then
  home=$HOME
  XDG_CONFIG_HOME="$home/.config"
  confirm_exe "home: $home |||| XDG_CONFIG_HOME: $XDG_CONFIG_HOME (XDG_CONFIG_HOMEが合っているか確認してください)"
  [ -e $home/local/bin ] || mkdir -p $home/local/bin # ユーザー独自のスクリプト格納場所
  [ -e $home/tmp ]       || mkdir -p $home/tmp

  if ! command -v mise >/dev/null; then
    install_mise
  fi
  if command -v mise >/dev/null; then
    mise install
  fi

  create_symlink "$home/moove/tak/dotfiles/tmux"    "$XDG_CONFIG_HOME/tmux"
  create_symlink "$home/moove/tak/dotfiles/git"     "$XDG_CONFIG_HOME/git"
  create_symlink "$home/moove/tak/dotfiles/sheldon" "$XDG_CONFIG_HOME/sheldon"
  create_symlink "$home/moove/tak/dotfiles/nvim"    "$XDG_CONFIG_HOME/nvim"
  create_symlink "$home/moove/tak/dotfiles/.config.local/mise"     "$XDG_CONFIG_HOME/mise"
  create_symlink "$home/moove/tak/dotfiles/.zshrc"                 "$home/.zshrc"
else
  home='/home/edge-dev/moove/tak'
  mkdir -p $XDG_CONFIG_HOME
  create_symlink "$home/dotfiles/git"     "$XDG_CONFIG_HOME/git"
  create_symlink "$home/dotfiles/sheldon" "$XDG_CONFIG_HOME/sheldon"
  create_symlink "$home/dotfiles/nvim"    "$XDG_CONFIG_HOME/nvim"
fi
eval "$(sheldon source)"

