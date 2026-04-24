return {
  "sindrets/diffview.nvim",
  config = function ()
    require("diffview").setup()
  end,
  lazy = false,
  keys = {
    {mode = "n", "<leader>hh", "<cmd>DiffviewOpen HEAD~1<CR>", desc = "1つ前とのdiff"},
    {mode = "n", "<leader>hf", "<cmd>DiffviewFileHistory %<CR>", desc = "ファイルの変更履歴"},
    {mode = "n", "<leader>hc", "<cmd>DiffviewClose<CR>", desc = "diffの画面閉じる"},
    {mode = "n", "<leader>hd", "<cmd>Diffview<CR>", desc = "コンフリクト解消画面表示"},
  },
}
