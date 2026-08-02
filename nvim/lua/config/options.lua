-- 一般的なオプション設定

-- Vimの内部文字コードはUTF-8を維持
vim.opt.encoding = 'utf-8'

-- ファイルを読み込む際、EUC-JPとShift-JISの判別を優先させる
-- fileencodingsはカンマ区切りの文字列として設定します
vim.opt.fileencodings = 'ucs-bom,utf-8,euc-jp,sjis,latin1'

vim.opt.swapfile = false

-- 外部で変更されたファイルを自動で読み直す(下の checktime autocmd と併用。旧 vim-autoread の代替)
vim.opt.autoread = true

vim.opt.number = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.clipboard = "unnamedplus"

-- ヤンクを手元(SSH クライアント側)のクリップボードへ OSC 52 で送る。
-- Herdr は pane が出した OSC 52 をクライアントのクリップボードへ転送するのでこれで届く。
-- 明示指定しないと nvim の provider 自動判定が先に tmux を掴み(残存 tmux サーバーがあると
-- $TMUX 無しでも tmux list-buffers が成功して採用される)、誰も見ない tmux バッファに入る。
-- また clipboard=unnamedplus のときは自動判定が OSC 52 に落ちない仕様。
-- paste は端末への問い合わせ(応答待ちで固まりうる)を避け、nvim 内の無名レジスタを返す。
--
-- ただし herdr-mirror のミラーペインだけは OSC 52 では届かない。ミラーは
-- `herdr terminal session observe|control` の画面フレーム(セル単位の CUP+SGR+文字)しか
-- 受け取らず、pane の OSC 52 は herdr 内部の別チャネルで herdr 自身のクライアントへ
-- 流れるため、ミラー越しのストリームには一切現れない(実測で確認)。そこでヤンクを
-- base64 1 行としてペイン単位のファイルにも追記し、ミラーの pane wrapper
-- (dotfiles/herdr/patches/mirror-clipboard-bridge.patch)が tail -F で拾って手元の端末へ
-- OSC 52 を出す。herdr のペイン外($HERDR_PANE_ID 無し)では何もしない。
local bridge_dir = vim.fn.expand("~/.cache/herdr-mirror-clip")
local bridge_max = 1024 * 1024

local function bridge_write(lines)
  local pane = vim.env.HERDR_PANE_ID
  if not pane or pane == "" then
    return
  end
  if vim.fn.isdirectory(bridge_dir) == 0 then
    -- ヤンク内容が平文で残るので 0700 固定
    vim.fn.mkdir(bridge_dir, "p", tonumber("700", 8))
  end
  local path = bridge_dir .. "/" .. pane
  -- 追記で伸ばし続けない。tail -F は truncate を検知して読み直すので、切り詰めた
  -- 直後の 1 行が再送されるだけで実害はない。
  local st = vim.uv.fs_stat(path)
  local f = io.open(path, (st and st.size > bridge_max) and "w" or "a")
  if not f then
    return
  end
  f:write(vim.base64.encode(table.concat(lines, "\n")) .. "\n")
  f:close()
end

local function osc52_copy_with_bridge(reg)
  local osc52 = require("vim.ui.clipboard.osc52").copy(reg)
  return function(lines, regtype)
    osc52(lines, regtype)
    -- ブリッジが転んでもヤンクそのものは成功させる
    pcall(bridge_write, lines)
  end
end

vim.g.clipboard = {
  name = "osc52",
  copy = {
    ["+"] = osc52_copy_with_bridge("+"),
    ["*"] = osc52_copy_with_bridge("*"),
  },
  paste = {
    ["+"] = function()
      return vim.split(vim.fn.getreg('"'), "\n")
    end,
    ["*"] = function()
      return vim.split(vim.fn.getreg('"'), "\n")
    end,
  },
}

-- 行末空白の表示
vim.opt.list = true
vim.opt.listchars:append("space:⋅")
vim.opt.listchars:append("eol:↴")
vim.opt.listchars:append("tab:▸ ")
vim.opt.listchars:append("trail:•")

-- treesitter用の設定
vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"
vim.o.foldlevel = 99 -- デフォルトで全て展開

-- ファイルタイプの追加
vim.filetype.add({
  extension = {
    ddl = 'sql',
  },
})
