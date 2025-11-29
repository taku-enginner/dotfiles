return {
  {
    "rcarriga/nvim-notify",
    config = function()
      require("notify").setup({
        timeout = 60000, -- ✅ 通知のタイムアウトはここで一元管理
        render = "compact",
      })
      vim.keymap.set("n", "<leader>nd", function()
        require("notify").dismiss({ pending = true, silent = true })
      end, { desc = "通知（message）をすべて削除" })
    end,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify", -- ✅ 依存関係をここに明記する
    },
  },
}
