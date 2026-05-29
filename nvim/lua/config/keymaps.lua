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
