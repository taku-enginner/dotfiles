#!/usr/bin/env zsh
set -euo pipefail

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

# 3状態で冪等にシンボリックリンクを張る:
#   1. 既に意図どおりのリンク -> 無音スキップ
#   2. 別物(違うリンク/実ファイル/ディレクトリ) -> 確認のうえ張り直し
#   3. 無し -> 作成
# リンク元が存在しなければエラー停止(壊れたリンクを作らない)。
create_symlink() {
  local src=$1 dst=$2
  if [ ! -e "$src" ]; then
    echo "エラー: リンク元が存在しません: $src" >&2
    return 1
  fi
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "同名のファイル/リンクが既に存在します: $dst"
    if confirm_exe "削除してシンボリックリンクを作成しますか?"; then
      rm -rf "$dst"
      ln -s "$src" "$dst"
      echo "シンボリックリンクを作成しました: $dst -> $src"
    fi
    return 0
  fi
  ln -s "$src" "$dst"
  echo "シンボリックリンクを作成しました: $dst -> $src"
}

install_sheldon() {
  curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh |
    bash -s -- --repo rossmacarthur/sheldon --to "$HOME/.local/bin"
}

# --- パス導出(ホスト名に依存しない) ---
DOTFILES_DIR=$(cd "$(dirname "${(%):-%x}")" && pwd)

# --- XDG_CONFIG_HOME を選択(設定済みならそれを既定に、未設定なら ~/.config) ---
echo "XDG_CONFIG_HOME をどちらにしますか:"
echo "  1) $HOME/.config            (XDG標準)"
echo "  2) $HOME/moove/tak/.config  (従来の moove 環境)"
echo -n "選択 (1/2) [${XDG_CONFIG_HOME:-$HOME/.config}] --> "
read -r xdg_choice
case "$xdg_choice" in
  1) XDG_CONFIG_HOME="$HOME/.config" ;;
  2) XDG_CONFIG_HOME="$HOME/moove/tak/.config" ;;
  *) XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}" ;;  # 空入力 = 現状/既定
esac

# シェル起動時(ツール初期化より前)に効かせる必要があるため ~/.zshenv に永続化(マシンローカル)
zshenv="$HOME/.zshenv"
if [ -f "$zshenv" ] && grep -q '^export XDG_CONFIG_HOME=' "$zshenv"; then
  sed -i "s#^export XDG_CONFIG_HOME=.*#export XDG_CONFIG_HOME=\"$XDG_CONFIG_HOME\"#" "$zshenv"
else
  echo "export XDG_CONFIG_HOME=\"$XDG_CONFIG_HOME\"" >> "$zshenv"
fi

echo "DOTFILES_DIR:    $DOTFILES_DIR"
echo "XDG_CONFIG_HOME: $XDG_CONFIG_HOME ($zshenv に保存)"
echo "HOME:            $HOME"

# --- ディレクトリ作成 ---
mkdir -p "$HOME/.local/bin" "$XDG_CONFIG_HOME"

# --- シンボリックリンク(mise install より前に張る必要がある) ---
create_symlink "$DOTFILES_DIR/tmux"    "$XDG_CONFIG_HOME/tmux"
create_symlink "$DOTFILES_DIR/git"     "$XDG_CONFIG_HOME/git"
create_symlink "$DOTFILES_DIR/sheldon" "$XDG_CONFIG_HOME/sheldon"
create_symlink "$DOTFILES_DIR/nvim"    "$XDG_CONFIG_HOME/nvim"
create_symlink "$DOTFILES_DIR/mise"    "$XDG_CONFIG_HOME/mise"
create_symlink "$DOTFILES_DIR/.zshrc"  "$HOME/.zshrc"

# --- sheldon(必須): 未導入なら自動インストール ---
if ! command -v sheldon >/dev/null && [ ! -x "$HOME/.local/bin/sheldon" ]; then
  echo "sheldon をインストールします..."
  install_sheldon
fi

# --- mise(任意): 未導入なら確認のうえインストール ---
if ! command -v mise >/dev/null && [ ! -x "$HOME/.local/bin/mise" ]; then
  if confirm_exe "mise をインストールしますか?"; then
    curl https://mise.run | sh
  fi
fi

# --- mise install(mise があれば config.toml に基づきツール導入) ---
mise_bin=$(command -v mise || echo "$HOME/.local/bin/mise")
if [ -x "$mise_bin" ]; then
  "$mise_bin" install
fi

# --- private dotfiles(業務プロジェクト固有設定: secrets・AWS profile・bastion・作業ディレクトリ等)を clone ---
# 認証は git 標準のプロンプト(GitHub ユーザー名 + PAT)。失敗・中止しても汎用設定は維持。
private_dir="$HOME/dotfiles-private"
private_url="https://github.com/taku-enginner/dotfiles-private.git"
if [ -d "$private_dir/.git" ]; then
  echo "private dotfiles は既に存在: $private_dir"
elif confirm_exe "private dotfiles (業務プロジェクト固有設定) を clone しますか? ($private_url)"; then
  git clone "$private_url" "$private_dir" ||
    echo "警告: private dotfiles の clone に失敗。汎用設定のみで続行します。" >&2
fi

# --- ccsession(claude --resume 用 fzf セッションピッカー)を ~/utils に clone + build ---
# alias は ~/utils/ccsession/ccsession(ビルド済みバイナリ)を参照するため build まで行う。
ccsession_dir="$HOME/utils/ccsession"
ccsession_url="https://github.com/sorafujitani/ccsession.git"
if [ -x "$ccsession_dir/ccsession" ]; then
  echo "ccsession は既に導入済み: $ccsession_dir/ccsession"
elif confirm_exe "ccsession を clone してビルドしますか?"; then
  mkdir -p "$HOME/utils"
  [ -d "$ccsession_dir/.git" ] || git clone "$ccsession_url" "$ccsession_dir" ||
    echo "警告: ccsession の clone に失敗。" >&2
  go_bin=$(command -v go || true)
  if [ -z "$go_bin" ] && command -v mise >/dev/null; then
    go_bin=$(mise which go 2>/dev/null || true)
  fi
  if [ -n "$go_bin" ] && [ -d "$ccsession_dir" ]; then
    (cd "$ccsession_dir" && "$go_bin" build -o ccsession ./cmd/ccsession) &&
      echo "ccsession をビルドしました: $ccsession_dir/ccsession" ||
      echo "警告: ccsession のビルドに失敗。" >&2
  else
    echo "警告: go が見つからず ccsession をビルドできません(mise で go を導入してください)。" >&2
  fi
fi
