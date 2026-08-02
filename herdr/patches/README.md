# herdr プラグインのローカルパッチ

`herdr/plugins/` は herdr が管理する実体（git checkout + ビルド成果物）で
`.gitignore` 済み。プラグイン更新で消えるローカル修正はここに patch として残す。

**適用順**: `mirror-keep-mouse-grab.patch` → `mirror-drag-select.patch`
→ `mirror-clipboard-bridge.patch`（いずれも前のものを前提にした差分）。

## mirror-keep-mouse-grab.patch

対象: `nikok6/herdr-mirror` v0.1.14 (`src/pane.rs`)

ミラーペインでマウスホイールのスクロールが効かなくなる問題の修正。

upstream はリモートの前景プロセスがシェルだとローカルのマウスグラブを外す
(`?1002l`)。しかしミラーペインは代替画面 (`?1049h`) で描画されるため herdr 側に
スクロールできるスクロールバックが無く (`pane.scroll.max_offset_from_bottom == 0`)、
ホイールはどこにも届かず消える。しかもグラブを外すとマウス入力自体が届かなくなるため、
ホイール操作では前景の再判定も起こらない片道トラップになっている。
`mirror.remote-split-*` で作ったペインは素のシェルプロンプトで始まるので、
分割した瞬間からホイールが死ぬ。

パッチはグラブを常時保持する。シェル時のクリック/ドラッグは元から
`mouse_action()` が捨てているので、リモートのプロンプトへ漏れることはない。
代償はシェル前景のミラーペインで herdr ネイティブのドラッグ選択が使えないこと
——これは `mirror-drag-select.patch` が自前の選択実装で解消した。

## mirror-drag-select.patch

対象: `nikok6/herdr-mirror` v0.1.14 (`src/grid.rs`, `src/pane.rs`)

ミラーペインでドラッグしてもコピーできない問題の修正。

- 素のドラッグ → **どのミラーペインでも**ローカルの選択。離した時点で OSC 52 で
  ホストのクリップボードへコピー（herdr は pane の OSC 52 を外の端末へ通すので、
  clip.exe のようなプラットフォーム依存のバイナリが要らない）
- `Alt`+ドラッグ → Alt ビットを外してリモートへ転送。リモート側の nvim などが
  自前のマウス操作に使う（既定 `mouse=nvi` なので何もしないとマウスが死ぬ）。
  **Alt 修飾が Windows Terminal と herdr を通過してここまで届くことは実機で確認済み
  (2026-08-02)**。将来 WT 側の変更で届かなくなったら `MOUSE_ALT` を ctrl(+16) に
  変える（`mouse_action()` の 1 行）
- 中／右ボタンは upstream の前景ベースの振り分けを維持（TUI へは転送、シェルでは
  破棄）。nvim の中クリック貼り付けが生き、シェルのプロンプトは汚れない
- **observe モード（read-only）でも選択できる**。upstream の observe 分岐は
  ホイール以外のマウスを全部捨てていたが、選択とコピーは純粋にローカルな読み取り
  操作なので、コピーのためにリモートのロックを奪う必要はない。ホイールが control
  を取りに行く既存の挙動はそのまま。ただし observe 中は Alt+ドラッグの転送は
  できない（書き込み権が無い）

**なぜ herdr のネイティブ選択に任せないのか**: ミラーの observe ストリームは CUP
絶対位置のフレームで、`Grid::apply` は `H`/`m`/`J`/`?25` しか解釈しない。
`Renderer::paint` も各行を `\x1b[{r};1H` + 行 + `\x1b[K` で描くため、**ローカル
herdr 側にも折り返しフラグが立たない**。つまりグラブを herdr に明け渡しても
「見た目の行」しか取れず、Windows Terminal の Shift+ドラッグと同じ結果になる。
選択を wrapper が持てば、ペイン境界の内側だけを対象にでき、行末の余白も落とせる。

制約と挙動:

- 選択できるのは**可視領域のみ**（ミラーペインにローカルのスクロールバックが無い）。
  画面外はホイールでリモート側を遡ってから選ぶ
- 折り返された 1 行は**複数行として**コピーされる（上記のとおり折り返し情報が
  存在しない）。正確な原文が要るなら `herdr pane read --source recent-unwrapped`
- 選択中にリモートのフレームが**選択範囲の中身を書き換えた**場合は選択を破棄する
  （画面座標に固定された選択が、見えているものと食い違わないようにするため）。
  画面の別の場所が更新されただけなら選択は残る
- OSC 52 は 100KB のペイロードまで実測で通っている（Windows Terminal）。
  `OSC52_MAX` を超える選択はコピーせず status 行に警告を出す

## mirror-clipboard-bridge.patch

対象: `nikok6/herdr-mirror` v0.1.14 (`src/pane.rs`)

ミラーペイン内のリモート nvim でヤンクしても手元のクリップボードに入らない問題の修正。
**`dotfiles/nvim/lua/config/options.lua` の `vim.g.clipboard` とセットで初めて機能する**
（片方だけでは何も起きない）。

**なぜ OSC 52 では届かないのか**: ミラーが受け取るのは
`herdr terminal session observe|control` の JSON フレームだけで、中身は画面グリッドの
再構成 ANSI（`{"bytes":…,"encoding":"ansi","full":…,"seq":…,"type":"terminal.frame"}`）。
herdr は pane が出した OSC 52 を `pane::osc::Osc52Forwarder` で拾って
`ServerMessage::Clipboard` として **herdr 自身のクライアント**へ流す設計なので、
画面フレームには最初から乗らない。observe / control の両方で実測して確認した
(herdr 0.7.5, 2026-08-02) ——リモートのペインで OSC 52 を発行させても、フレームに
現れるのは画面に表示されたコマンド文字列だけで、制御シーケンス `ESC]52;` は 1 つも来ない。
`ssh -t <host> herdr` の直アタッチなら OSC 52 はそのまま届く。ミラー越しだけの問題。

経路:

```
リモート nvim yank
  ├→ OSC 52          (直アタッチ用。従来どおり)
  └→ ~/.cache/herdr-mirror-clip/<pane_id> に base64 を 1 行追記
        ↑ ssh (ControlMaster に相乗り) + tail -n0 -F
   ミラーの pane wrapper → \e]52;c;… → 手元の端末
```

- ブリッジファイルは**リモートのペイン単位**（nvim 側が `$HERDR_PANE_ID` で決める）。
  ミラーペインが何枚あっても取り違え・重複コピーは起きない
- 購読は wrapper の**生存期間で 1 本**。セッション（observe/control）には紐づけない
  ——ファイルがペイン単位なのでモード切替に再ターゲットするものが無く、observe 中の
  ヤンクも拾えた方が自然。ペイン終了時は `stop_clip_watch` が ssh を落とす
- ssh が切れたら `CLIP_RETRY`(5 秒) 後に張り直す。ブリッジが死んでもペインは無事
- `$HERDR_PANE_ID` が無い環境（素の ssh）では nvim 側が何も書かないので、
  直アタッチ運用は一切変わらない
- 上限は既存の `OSC52_MAX`(100KB) を base64 の 4/3 換算で流用。超えたら status 行に
  警告を出してクリップボードには触らない
- base64 の文字集合を検証してから端末へ書く（壊れた行をそのまま端末に流さない）

### 再適用（`herdr plugin update` などで消えたとき）

```sh
cd ~/.config/herdr/plugins/github/mirror-*
git apply ~/dotfiles/herdr/patches/mirror-keep-mouse-grab.patch
git apply ~/dotfiles/herdr/patches/mirror-drag-select.patch
git apply ~/dotfiles/herdr/patches/mirror-clipboard-bridge.patch
mise exec rust@stable -- cargo build --release   # install.sh の prebuilt を上書きする
./target/release/herdr-mirror teardown && ./target/release/herdr-mirror start
```

**最後の teardown → start は必須**（省くとミラーが壊れる）。daemon はペインの起動
コマンドを `std::env::current_exe()` から組み立てる（`src/mirror.rs`）。リビルドで
実行ファイルを差し替えると、走り続けている古い daemon の `current_exe()` は
`…/herdr-mirror (deleted)` を返すようになり、ペインが exit 127（command not found）で
即死する。症状は「`mirror.restore` でワークスペースが一瞬出てすぐ消える」で、
daemon ログには `creating mirror workspace` → 1 秒後に
`workspace mirror for … was closed locally — tombstoning` が並ぶ。
`readlink /proc/$(pgrep -f 'herdr-mirror daemon')/exe` に `(deleted)` が付いていたらこれ。
