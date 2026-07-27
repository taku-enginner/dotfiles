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
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- オプション設定（lazy 読み込み前に適用）
require("config.options")

-- Setup lazy.nvim
require("lazy").setup({
  -- plugins/ 配下を自動 import（プラグイン追加はファイルを置くだけ）
  spec = {
    { import = "plugins" },
  },
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "tokyonight" } },
  -- 更新チェックは行うが起動時に通知しない（更新有無は :Lazy で確認）
  checker = { enabled = true, notify = false },
  -- 設定変更時の自動リロードは残し、通知だけ止める
  change_detection = { notify = false },
  git = {
    timeout = 600,
  }
})

-- キーマップ・autocmd（プラグイン読み込み後に適用）
require("config.keymaps")
require("config.autocmds")
