return {
  "nvimdev/lspsaga.nvim",
  event = "LspAttach",
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- optional
  opts = {},
  keys = {
    { "gh", "<cmd>Lspsaga lsp_finder<CR>", desc = "定義・参照を検索" },
    { "gD", "<cmd>Lspsaga peek_definition<CR>", desc = "定義をプレビュー" },
    { "gd", "<cmd>Lspsaga goto_definition<CR>", desc = "定義へジャンプ" },
    { "gr", "<cmd>Lspsaga rename<CR>", desc = "リネーム" },
    { "gp", "<cmd>Lspsaga peek_type_definition<CR>", desc = "型定義をプレビュー" },
    { "gt", "<cmd>Lspsaga goto_type_definition<CR>", desc = "型定義へジャンプ" },
    { "K", "<cmd>Lspsaga hover_doc<CR>", desc = "ホバードキュメント" },
    { "<leader>ca", "<cmd>Lspsaga code_action<CR>", desc = "コードアクション" },
    { "<leader>sl", "<cmd>Lspsaga show_line_diagnostics<CR>", desc = "行の診断を表示" },
    { "<leader>sc", "<cmd>Lspsaga show_cursor_diagnostics<CR>", desc = "カーソル位置の診断を表示" },
    { "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", desc = "前の診断へ" },
    { "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>", desc = "次の診断へ" },
    { "<leader>o", "<cmd>Lspsaga outline<CR>", desc = "アウトライン表示" },
  },
}
