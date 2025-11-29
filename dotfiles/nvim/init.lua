-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Vimの内部文字コードはUTF-8を維持
vim.opt.encoding = 'utf-8'

-- ファイルを読み込む際、EUC-JPとShift-JISの判別を優先させる
-- fileencodingsはカンマ区切りの文字列として設定します
vim.opt.fileencodings = 'ucs-bom,utf-8,euc-jp,sjis,latin1'

vim.opt.swapfile = false

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins/autopairs" },
    { import = "plugins/autoread" },
    { import = "plugins/auto-save" },
    { import = "plugins/bufferline" },
    { import = "plugins/cmp" },
    { import = "plugins/copilot" },
    { import = "plugins/copilot-chat" },
    { import = "plugins/dashboard" },
    { import = "plugins/diffview" },
    { import = "plugins/git-messenger" },
    { import = "plugins/gitsigns" },
    { import = "plugins/git-blame" },
    { import = "plugins/indent-blankline" },
    --{ import = "plugins/lastplace" },
    { import = "plugins/lsp" },
    { import = "plugins/lspsaga" },
    { import = "plugins/markdown-preview" },
    { import = "plugins/nerdcommenter" },
    { import = "plugins/noice" },
    { import = "plugins/nvim-bqf" },
    { import = "plugins/osc52" },
    { import = "plugins/telescope" },
    { import = "plugins/telescope-live-grep-args" },
    { import = "plugins/todo-comments" },
    { import = "plugins/toggle-cheatsheet" },
    { import = "plugins/tokyonight" },
    --{ import = "plugins/translator" },
    { import = "plugins/treesitter" },
    { import = "plugins/treesj" },
    { import = "plugins/venn" },
    { import = "plugins/vim-fugitive" },
    { import = "plugins/vim-easy-align" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "tokyonight" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
  git = {
    timeout = 600,
  }
})

vim.filetype.add({
  extension = {
    ddl = 'sql',
  },
})

-- 一般的なオプション設定
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.g.mapleader = " "
vim.opt.clipboard = "unnamedplus"

-- キーマップ設定
vim.keymap.set("n", "P", "P`]", { desc = "Paste and move to the end" })
vim.keymap.set("n", "p", "p`]", { desc = "Paste and move to the end" })
vim.keymap.set('n', '<leader>p', ':echo expand(\'%\')<CR>', { desc = '現在のファイルパスをメッセージに表示' })
vim.keymap.set('n', '<leader>j', ':bprev<CR>', { desc = '前のバッファに移動' })
vim.keymap.set('n', '<leader>k', ':bnext<CR>', { desc = '次のバッファに移動' })
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'ファイルツリー表示' })

-- Visualモードでインデントしても選択状態を維持する
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- 保存時に空白削除
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "" },
  command = [[%s/\s\+$//e]],
})

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


-- ファイルタイプごとの設定
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "ruby" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.tt",
  callback = function()
    vim.opt_local.tabstop = 2       -- タブ1つ = 2スペース表示
    vim.opt_local.shiftwidth = 2    -- 自動インデントも2スペース
    vim.opt_local.expandtab = true  -- Tabキーでスペースを挿入
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.pm",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.sh",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.lua",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = ".*",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_set_keymap('i', '<C-l>', 'cmp#confirm()', {expr = true, noremap = true}) -- cmpの確定をCtrl+lに割り当て
vim.keymap.set('i', '<C-l>', 'copilot#Accept("<CR>")', {
  expr = true,
  replace_keycodes = false,
  desc = "Copilotの予測を挿入"
})

