return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify", -- 設定は plugins/notify.lua
  },
  opts = {
    lsp = {
      -- LSP の進捗表示は fidget.nvim に任せる(plugins/lsp.lua)
      progress = { enabled = false },
    },
  },
}
