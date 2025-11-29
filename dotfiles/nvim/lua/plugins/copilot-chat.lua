return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {
      -- See Configuration section for options
    },

    config = function(_, opts)
      -- プラグインのセットアップ
      require("CopilotChat").setup(opts)

      -- キーマップの設定
      local map = vim.keymap.set

      -- 新しいチャットウィンドウを開く
      -- 使い方: ノーマルモードで <leader>cc
      map("n", "<leader>ee", "<cmd>CopilotChat<CR>", { desc = "Open Copilot Chat" })
      
      -- ビジュアルモードで選択範囲をCopilotに質問する

      map("v", "<leader>q", "<cmd>CopilotChat<CR>", { desc = "Query selected code in Copilot Chat" })

      -- 特定のコマンドを直接実行するキーマップ
      -- 使い方: ノーマルモードで <leader>ce （Explain）、<leader\>cf （Fix）
      map("n", "<leader>ce", "<cmd>CopilotChatExplain<CR>", { desc = "Explain code" })
      map("n", "<leader>cf", "<cmd>CopilotChatFix<CR>", { desc = "Fix code" })
    end,
  },
}
