-- 通知 UI。noice.nvim のバックエンドも兼ねる(plugins/noice.lua 参照)
return {
  "rcarriga/nvim-notify",
  opts = {
    timeout = 60000, -- 通知のタイムアウトはここで一元管理
    render = "compact",
  },
  keys = {
    {
      "<leader>nd",
      function()
        require("notify").dismiss({ pending = true, silent = true })
      end,
      desc = "通知（message）をすべて削除",
    },
  },
}
