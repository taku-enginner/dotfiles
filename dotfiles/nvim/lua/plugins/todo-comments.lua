return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>tq", "<cmd>TodoQuickFix<cr>", desc = "TODOのクイックフィックスリストを確認" },
  },
  opts = {
    search = {
      command = "rg",
      args = {
        -- quickfixが解釈できる形式で出力するための引数
        "--vimgrep",
        -- 大文字小文字を区別しない
        "--smart-case",
        -- 隠しファイルやディレクトリも検索対象に含める
        "--hidden",
        -- .gitignore や .ignore ファイルを無視して検索する
        "--no-ignore",
        -- .git ディレクトリは検索から除外する
        "--glob",
        "!**/.git/*",
      },
    },
  },
}
