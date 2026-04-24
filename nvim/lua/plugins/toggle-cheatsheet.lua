return {
  "sudormrfbin/cheatsheet.nvim",

  cmd = "Cheatsheet",

  config = function()
    require("cheatsheet").setup({
      -- 🚨 この部分を追加・修正します 🚨
      show_only = {
        -- 💡 True にしたカテゴリのみが表示されます
        plugins = true,   -- インストール済みプラグインのキーマップを表示
        telescope = false, -- Telescopeの組み込みヘルプを非表示
        cheatsheets = true, -- 自作のチートシート（/cheatsheetディレクトリ内）を表示
        builtin = false,    -- Vim/Neovimの組み込みコマンドを非表示 (4000件の原因)
        help = false,       -- :helpのハイパーリンクを非表示
        custom = true,      -- カスタムで定義したチートシートを表示
      },
      -- theme = "ivy", -- (オプション) テーマ設定
    })
  end,

  keys = {
    {"<leader>ch", "<cmd>Cheatsheet<CR>", desc = "Open Cheatsheet"},
  },

  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
}

