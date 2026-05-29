-- 保存時に空白削除
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "" },
  command = [[%s/\s\+$//e]],
})

-- ファイルタイプごとのインデント設定
-- FileType は BufRead より後に発火するため、下の catch-all より優先される

-- 4 インデント
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "perl" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})

-- 2 インデント
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "ruby", "typescript", "lua", "sh", "bash", "conf", "html", "css", "js", "json" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

-- 既定(上記以外)は 2 インデント
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = ".*",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

-- 拡張子指定で 2 インデント(*.inc / *.tt)
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.inc", "*.tt" },
  callback = function()
    vim.opt_local.tabstop = 2       -- タブ1つ = 2スペース表示
    vim.opt_local.shiftwidth = 2    -- 自動インデントも2スペース
    vim.opt_local.expandtab = true  -- Tabキーでスペースを挿入
  end,
})
