#!/bin/bash
#
# Gmail / Slack / 再生中曲を herdr のサイドバーへ出す systemd user サービスを登録する。
# 表示処理の実体は bin/herdr-ticker なので、ここでは unit ファイルだけを生成する。
# 資格情報はリポジトリ外の ~/.config/herdr-ticker-*.env に置く
# (このリポジトリは公開なので、秘密は作業ツリーに一切入れない)。
#
# 何度実行しても安全。env ファイルが無いソースはスキップして残りを入れる。

set -u

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
TICKER="$DOTFILES_DIR/bin/herdr-ticker"
SERVICE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
GMAIL_ENV="$CONFIG_DIR/herdr-ticker-gmail.env"
SLACK_ENV="$CONFIG_DIR/herdr-ticker-slack.env"

if [[ ! -x "$TICKER" ]]; then
  echo "実行できません: $TICKER"
  exit 1
fi

echo "セットアップを開始します..."

mkdir -p "$SERVICE_DIR" "$HOME/.local/bin"

# 対話利用向けの symlink。unit 側は dotfiles のパスを直接指すので必須ではない
if [[ ! -e "$HOME/.local/bin/herdr-ticker" ]]; then
  ln -s "$TICKER" "$HOME/.local/bin/herdr-ticker"
  echo "シンボリックリンクを作成しました: $HOME/.local/bin/herdr-ticker -> $TICKER"
fi

# unit から見た ticker のパス。%h はユーザーのホームディレクトリに置換される
exec_ticker="%h/${TICKER#"$HOME/"}"

units=(herdr-notify-ws)

cat << EOF > "$SERVICE_DIR/herdr-notify-ws.service"
[Unit]
Description=Ensure the herdr 'notify' workspace exists

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$exec_ticker ensure-workspace

[Install]
WantedBy=default.target
EOF

# 資格情報ファイルは本人だけが読める状態にしておく。
# 作るときの chmod 600 を忘れがちなので、ここで気付けるようにする。
harden_env() {
  local f="$1" mode
  mode=$(stat -c %a "$f")
  if [[ "$mode" != "600" ]]; then
    chmod 600 "$f"
    echo "⚠️ $f のパーミッションが $mode だったので 600 に直しました"
  fi
}

# 常駐サービスを 1 本ぶん書き出す。$1=名前 $2=説明 $3=引数 $4=EnvironmentFile(空可)
write_unit() {
  local name="$1" desc="$2" argv="$3" envfile="${4:-}"
  {
    printf '[Unit]\n'
    printf 'Description=%s\n' "$desc"
    printf 'After=network.target herdr-notify-ws.service\n'
    # notify の作成は前倒しに過ぎず、常駐側も各自で作り直せる。
    # 失敗しても道連れにしないよう Requires ではなく Wants にする。
    printf 'Wants=herdr-notify-ws.service\n\n'
    printf '[Service]\n'
    [[ -n "$envfile" ]] && printf 'EnvironmentFile=%s\n' "$envfile"
    printf 'ExecStart=%s %s\n' "$exec_ticker" "$argv"
    printf 'Restart=always\n'
    printf 'RestartSec=5\n\n'
    printf '[Install]\n'
    printf 'WantedBy=default.target\n'
  } > "$SERVICE_DIR/${name}.service"
  units+=("$name")
}

# --- Gmail ---
if [[ -f "$GMAIL_ENV" ]]; then
  harden_env "$GMAIL_ENV"
  write_unit herdr-gmail "Gmail Unread Count -> herdr sidebar" gmail \
    "%h/${GMAIL_ENV#"$HOME/"}"
else
  cat <<EOF

--- Gmail はスキップします ---
$GMAIL_ENV がありません。以下の 2 行を書いてから再実行してください (chmod 600)。

  GMAIL_USER=$(git config user.email 2>/dev/null || echo 'you@example.com')
  GMAIL_PASS=xxxx xxxx xxxx xxxx

GMAIL_PASS は Google アプリパスワード。2 段階認証が有効で、かつ
Workspace 管理者がアプリパスワードを禁止していない場合のみ発行できます。
  https://myaccount.google.com/apppasswords

EOF
fi

# --- Slack ---
if [[ -f "$SLACK_ENV" ]]; then
  harden_env "$SLACK_ENV"
  write_unit herdr-slack "Slack Mentions -> herdr sidebar" slack \
    "%h/${SLACK_ENV#"$HOME/"}"
else
  cat <<EOF

--- Slack はスキップします ---
$SLACK_ENV がありません。以下の 2 行を書いてから再実行してください (chmod 600)。

  SLACK_XOXC=xoxc-...
  SLACK_COOKIE_D=xoxd-...

取得手順:
  1. ブラウザで Slack を開く
  2. DevTools の Console で JSON.parse(localStorage.localConfig_v2).teams を実行し token をコピー
  3. DevTools の Application → Cookies → app.slack.com から d の値をコピー

EOF
fi

# --- 再生中曲 (Windows SMTC 経由・資格情報は不要) ---
write_unit herdr-nowplaying "Now Playing -> herdr sidebar" nowplaying

systemctl --user daemon-reload
systemctl --user enable --now "${units[@]/%/.service}"

echo
failed=0
for u in "${units[@]}"; do
  # oneshot は RemainAfterExit=yes なので is-active で判定できる
  if systemctl --user is-active --quiet "$u.service"; then
    printf '  ✅ %s\n' "$u"
  else
    printf '  ❌ %s\n' "$u"
    failed=1
  fi
done

echo
if [[ $failed -eq 0 ]]; then
  echo "🎉 成功: サービスは正常に稼働しています！"
  echo "herdr のサイドバーの notify ワークスペース配下に表示されます"
  echo "(行が出ない場合は herdr server reload-config で config.toml を読み直してください)"
else
  echo "⚠️ 警告: 起動に失敗したサービスがあります。以下で確認してください。"
  for u in "${units[@]}"; do
    systemctl --user is-active --quiet "$u.service" || \
      systemctl --user status "$u.service" --no-pager --lines=10
  done
  exit 1
fi
