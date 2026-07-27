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
