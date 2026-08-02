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
# 既存の XDG_CONFIG_HOME 行を全除去してから1行だけ追記(冪等)。
# sed -i '' は macOS 専用で Linux では中断するため grep フィルタで移植性を確保。
# grep -v が全行除去(=マッチ0)で exit 1 を返しても || true で握り、必ず mv して .tmp を残さない。
if [ -f "$zshenv" ]; then
  grep -v '^export XDG_CONFIG_HOME=' "$zshenv" > "$zshenv.tmp" 2>/dev/null || true
  mv "$zshenv.tmp" "$zshenv"
fi
echo "export XDG_CONFIG_HOME=\"$XDG_CONFIG_HOME\"" >> "$zshenv"

echo "DOTFILES_DIR:    $DOTFILES_DIR"
echo "XDG_CONFIG_HOME: $XDG_CONFIG_HOME ($zshenv に保存)"
echo "HOME:            $HOME"

# --- ディレクトリ作成 ---
mkdir -p "$HOME/.local/bin" "$XDG_CONFIG_HOME"

# --- シンボリックリンク(mise install より前に張る必要がある) ---
create_symlink "$DOTFILES_DIR/git"     "$XDG_CONFIG_HOME/git"
create_symlink "$DOTFILES_DIR/sheldon" "$XDG_CONFIG_HOME/sheldon"
create_symlink "$DOTFILES_DIR/nvim"    "$XDG_CONFIG_HOME/nvim"
create_symlink "$DOTFILES_DIR/mise"    "$XDG_CONFIG_HOME/mise"
create_symlink "$DOTFILES_DIR/.zshrc"  "$HOME/.zshrc"
# bin/ 配下のスクリプトは PATH の通った ~/.local/bin へ個別リンク
create_symlink "$DOTFILES_DIR/bin/cc-compose" "$HOME/.local/bin/cc-compose"
create_symlink "$DOTFILES_DIR/bin/herdr-keys" "$HOME/.local/bin/herdr-keys"
# herdr: $XDG_CONFIG_HOME/herdr をディレクトリごとリンクする。
# log/socket/session.json は herdr 自身が同ディレクトリに置くため .gitignore で除外済み。
# config.toml 単体をここでリンクしてはいけない(リンク元とリンク先が同一パスになり自己参照で壊れる)。
create_symlink "$DOTFILES_DIR/herdr" "$XDG_CONFIG_HOME/herdr"

# ============================================================
# Claude Code 設定の組み立て(baseline=~/claude 読取専用 ⊕ 個人=dotfiles/claude)
#   - ~/claude は会社 baseline のミラー。ここでは読むだけ・一切書き込まない。
#   - ~/claude/setup.sh は実行しない。このスクリプトが ~/.claude の組み立てを全部担う。
#   - 個人物(override/WSL断片/個人skill・hook)は dotfiles 側から供給し baseline を汚さない。
# ============================================================
CLAUDE_BASE_DIR="${CLAUDE_BASE_DIR:-$HOME/claude}"          # 会社 baseline(読取専用)
CLAUDE_PERSONAL_DIR="$DOTFILES_DIR/claude"                 # 個人設定(このリポ)
CLAUDE_OUT_DIR="$HOME/.claude"                             # 組み立て先
MOOVIBE_SKILLS_DIR="${MOOVIBE_SKILLS_DIR:-$HOME/work/moovibe/skills}"

# 丸ごと symlink を実ディレクトリへ置換(baseline と個人の両ソースから個別 link するため)
ensure_real_dir() {
  [ -L "$1" ] && rm -f "$1"
  mkdir -p "$1"
}

# CLAUDE.md: baseline ＋ 個人 override を連結して実ファイル生成。
# symlink にすると personal-context の ensure-global-rules.sh フックが baseline 本体へ
# 追記して汚染するため、必ず実ファイルにする。
generate_claude_md() {
  local base="$CLAUDE_BASE_DIR/CLAUDE.md"
  local override="$CLAUDE_PERSONAL_DIR/CLAUDE.override.md"
  local out="$CLAUDE_OUT_DIR/CLAUDE.md"
  if [ ! -f "$base" ]; then
    echo "CLAUDE.md base 不在: $base" >&2
    return 1
  fi
  local tmp
  tmp="$(mktemp)"
  if ! cat "$base" > "$tmp"; then rm -f "$tmp"; return 1; fi
  if [ -f "$override" ]; then
    printf '\n' >> "$tmp"
    cat "$override" >> "$tmp"
  fi
  if [ -e "$out" ] || [ -L "$out" ]; then rm -f "$out"; fi
  mv "$tmp" "$out" || { rm -f "$tmp"; return 1; }
  echo "生成: $out (baseline ＋ override)"
}

# settings.json: baseline ⊕ 個人 override を jq で合成して実ファイル生成。
# マージ規則は Claude Code 本体に合わせる(配列=結合／オブジェクト=deep merge／スカラー=後勝ち)。
generate_settings() {
  local base="$CLAUDE_BASE_DIR/settings.json"
  local override="$CLAUDE_PERSONAL_DIR/settings.override.json"
  local out="$CLAUDE_OUT_DIR/settings.json"
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq が無いため $out を生成できません(jq 導入後に再実行)" >&2
    return 1
  fi
  if [ ! -f "$base" ]; then
    echo "settings base 不在: $base" >&2
    return 1
  fi
  local inputs=("$base")
  [ -f "$override" ] && inputs+=("$override")
  local merge_prog='def m($a;$b):
    if   ($a|type)=="object" and ($b|type)=="object"
    then reduce ($b|keys_unsorted[]) as $k ($a; .[$k] = m(.[$k]; $b[$k]))
    elif ($a|type)=="array"  and ($b|type)=="array" then $a + $b
    else $b end;
    reduce .[1:][] as $o (.[0]; m(.; $o))'
  local tmp
  tmp="$(mktemp)"
  if jq -s "$merge_prog" "${inputs[@]}" > "$tmp"; then
    if [ -e "$out" ] || [ -L "$out" ]; then rm -f "$out"; fi
    mv "$tmp" "$out"
    echo "生成: $out (${#inputs[@]} ソース合成)"
  else
    echo "jq マージ失敗($out は変更せず)" >&2
    rm -f "$tmp"
    return 1
  fi
}

# skills: 実ディレクトリ ＋ 個別 symlink(baseline ＋ 個人 ＋ moovibe)。
# ~/.claude/skills を実dir化することで、どのリポの作業ツリーも汚さない。
link_skills() {
  local dst="$CLAUDE_OUT_DIR/skills"
  ensure_real_dir "$dst"
  local s
  for s in "$CLAUDE_BASE_DIR/skills"/*(N/); do
    create_symlink "$s" "$dst/${s:t}"
  done
  for s in "$CLAUDE_PERSONAL_DIR/skills"/*(N/); do
    create_symlink "$s" "$dst/${s:t}"
  done
  if [ -d "$MOOVIBE_SKILLS_DIR" ]; then
    for s in "$MOOVIBE_SKILLS_DIR"/*(N/); do
      create_symlink "$s" "$dst/${s:t}"
    done
  else
    echo "moovibe 未検出のため個人スキルのリンクをスキップ: $MOOVIBE_SKILLS_DIR" >&2
  fi
}

# hooks: 実ディレクトリ ＋ baseline hook の個別 symlink。
# herdr 管理hook(herdr-*)は symlink せず実ファイルとして退避→復元し、herdr に管理を委ねる
# (herdr は再インストールで上書きするため dotfiles では追跡しない)。
link_hooks() {
  local dst="$CLAUDE_OUT_DIR/hooks"
  local herdr_bak=""
  if [ -e "$dst/herdr-agent-state.sh" ]; then
    herdr_bak="$(mktemp)"
    cat "$dst/herdr-agent-state.sh" > "$herdr_bak" 2>/dev/null || { rm -f "$herdr_bak"; herdr_bak=""; }
  fi
  ensure_real_dir "$dst"
  local h
  for h in "$CLAUDE_BASE_DIR/hooks"/*(N.); do
    case "${h:t}" in herdr-*) continue ;; esac
    create_symlink "$h" "$dst/${h:t}"
  done
  for h in "$CLAUDE_PERSONAL_DIR/hooks"/*(N.); do
    create_symlink "$h" "$dst/${h:t}"
  done
  if [ -n "$herdr_bak" ]; then
    cp "$herdr_bak" "$dst/herdr-agent-state.sh"
    chmod +x "$dst/herdr-agent-state.sh"
    rm -f "$herdr_bak"
    echo "herdr hook を実ファイルとして復元(以後 herdr が管理)"
  fi
}

# crontab に週次昇格スクリプトを登録(毎週金曜 19:47)
setup_claude_cron() {
  local cron_line="47 19 * * 5 $CLAUDE_OUT_DIR/hooks/weekly-promote.sh"
  if crontab -l 2>/dev/null | grep -qF "weekly-promote.sh"; then
    echo "crontab 登録済み: weekly-promote.sh"
    return 0
  fi
  if confirm_exe "weekly-promote.sh を crontab に追加しますか? (毎週金曜 19:47)"; then
    (crontab -l 2>/dev/null; echo "$cron_line") | crontab -
    echo "crontab に追加: $cron_line"
  fi
}

# MCP サーバー(playwright, context7)を導入
setup_mcp_servers() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "claude CLI が見つからないため MCP 導入をスキップ"
    return 0
  fi
  if claude mcp get playwright >/dev/null 2>&1; then
    echo "MCP 'playwright' は導入済み"
  elif confirm_exe "MCP server 'playwright' を導入しますか?"; then
    claude mcp add -s user playwright -- npx @playwright/mcp@latest --browser chromium
  fi
  if claude mcp get context7 >/dev/null 2>&1; then
    echo "MCP 'context7' は導入済み"
  elif confirm_exe "MCP server 'context7' を導入しますか? (API キーが必要)"; then
    local api_key="${CONTEXT7_API_KEY:-}"
    if [ -z "$api_key" ]; then
      echo -n "CONTEXT7_API_KEY を入力 --> "
      read -rs api_key
      echo
    fi
    claude mcp add --transport http -s user context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: ${api_key}"
  fi
}

# プラグインマーケットプレイス(claude-plugins-official)を追加
setup_plugin_marketplaces() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "claude CLI が見つからないため marketplace 追加をスキップ"
    return 0
  fi
  if claude plugin marketplace list 2>/dev/null | grep -q 'claude-plugins-official'; then
    echo "marketplace 'claude-plugins-official' は追加済み"
  elif confirm_exe "marketplace 'anthropics/claude-plugins-official' を追加しますか?"; then
    claude plugin marketplace add anthropics/claude-plugins-official
  fi
}

setup_claude() {
  if [ ! -d "$CLAUDE_BASE_DIR" ]; then
    echo "Claude baseline が無いため ~/.claude の組み立てをスキップ: $CLAUDE_BASE_DIR" >&2
    return 0
  fi
  mkdir -p "$CLAUDE_OUT_DIR"

  # baseline の単一ファイル/ディレクトリ(個人物なし)は symlink
  create_symlink "$CLAUDE_BASE_DIR/statusline.py" "$CLAUDE_OUT_DIR/statusline.py"
  create_symlink "$CLAUDE_BASE_DIR/memory"        "$CLAUDE_OUT_DIR/memory"

  # keybindings.json は baseline に無い個人設定なので dotfiles から直リンク(マージ不要)
  create_symlink "$CLAUDE_PERSONAL_DIR/keybindings.json" "$CLAUDE_OUT_DIR/keybindings.json"

  generate_claude_md
  generate_settings
  link_skills
  link_hooks

  # personal-context 連携は 2026-08-02 に撤去(コンテキスト削減)。
  #   - commands の whole-dir symlink をやめた(11 個のスラッシュコマンドは personal-context
  #     ディレクトリで作業する時だけ効く。全ディレクトリに要らない)
  #   - statusLine の override をやめ baseline の statusline.py に戻した
  #   - CLAUDE.override.md の global_rules import をやめた
  # 戻したい時は git log で本コミットを参照。

  # user レベルの settings.local.json は Claude Code に読まれない(死にファイル)ので掃除
  if [ -f "$CLAUDE_OUT_DIR/settings.local.json" ]; then
    rm -f "$CLAUDE_OUT_DIR/settings.local.json"
    echo "読まれない settings.local.json を削除"
  fi

  setup_claude_cron
  setup_mcp_servers
  # setup_plugin_marketplaces は 2026-08-02 に呼び出しを外した。
  # vercel / crit プラグインの説明文がスキル一覧を 30KB 超に膨らませていたため
  # settings.override.json から enabledPlugins / extraKnownMarketplaces を削除した。
  # marketplace を再登録すると次の起動でまた候補に載るので、追加もしない。
}

setup_claude

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

# --- hw(highway: 高速 grep)を未導入なら clone + build する ---
# 以前は .zshrc がシェル起動ごとに build していたが、起動を遅くするため setup.sh へ移設。
# build.sh は autotools チェーン(aclocal/autoconf/autoheader/automake → configure → make)。
# 依存が欠けると先頭の aclocal で即死するため、ビルド前に検査して導入コマンドを名指しする。
if ! command -v hw >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/hw" ]; then
  if confirm_exe "hw(highway) を clone してビルドしますか?"; then
    hw_missing=()
    for tool in aclocal automake autoconf autoheader make cc; do
      command -v "$tool" >/dev/null 2>&1 || hw_missing+=("$tool")
    done
    if [ ${#hw_missing[@]} -gt 0 ]; then
      echo "hw のビルドに必要なツールが不足しています: ${hw_missing[*]}" >&2
      case "$(uname -s)" in
        Darwin) echo "  → 導入: brew install automake autoconf gperftools" >&2 ;;
        Linux)  echo "  → 導入(Debian/Ubuntu 系): sudo apt-get install -y automake autoconf make gcc libgoogle-perftools-dev" >&2 ;;
        *)      echo "  → automake / autoconf / make / C コンパイラ を導入してください" >&2 ;;
      esac
      echo "  導入後に setup.sh を再実行してください(hw 以外の設定は継続します)。" >&2
    else
      hw_dir="$HOME/local/tmp/highway"
      mkdir -p "$(dirname "$hw_dir")"
      [ -d "$hw_dir/.git" ] || git clone https://github.com/tkengo/highway.git "$hw_dir" ||
        echo "警告: highway の clone に失敗。" >&2
      if [ -d "$hw_dir" ]; then
        if (cd "$hw_dir" && ./tools/build.sh) && mv "$hw_dir/hw" "$HOME/.local/bin/"; then
          echo "hw を導入しました: $HOME/.local/bin/hw"
        else
          echo "警告: hw のビルドに失敗。直上の aclocal/configure/make の出力を確認してください。" >&2
        fi
      fi
    fi
  fi
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
