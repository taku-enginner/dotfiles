return {
  "sindrets/diffview.nvim",
  opts = {},
  keys = {
    { "<leader>hh", "<cmd>DiffviewOpen HEAD~1<CR>", desc = "1つ前とのdiff" },
    { "<leader>hf", "<cmd>DiffviewFileHistory %<CR>", desc = "ファイルの変更履歴" },
    { "<leader>hc", "<cmd>DiffviewClose<CR>", desc = "diffの画面閉じる" },
    { "<leader>hd", "<cmd>Diffview<CR>", desc = "コンフリクト解消画面表示" },
  },
}
