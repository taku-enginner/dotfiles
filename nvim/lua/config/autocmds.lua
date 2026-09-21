-- 保存時に行末空白を削除
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- ファイルタイプごとのインデント設定
-- 既定値(2 インデント)は config/options.lua 側。ここは例外だけを書く

-- 4 インデント
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "perl" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})

-- 外部で変更されたファイルを自動リロード(旧 vim-autoread プラグインの代替)
-- autoread だけでは編集中に検知しないため、フォーカス/バッファ移動/カーソル静止で checktime する
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  command = "checktime",
})

-- .md ファイルはインサートモードを抜けた時に自動保存
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*.md",
  callback = function()
    -- 変更があり、通常の実ファイルバッファのときだけ保存
    if vim.bo.modified and vim.bo.modifiable
      and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
})

-- リロードが起きたことを通知(nvim-notify があればそちらに表示される)
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  pattern = "*",
  callback = function()
    vim.notify("ファイルがディスク上で変更されたため再読み込みしました", vim.log.levels.WARN)
  end,
})
