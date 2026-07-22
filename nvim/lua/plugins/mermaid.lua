return {
  "kevalin/mermaid.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("mermaid").setup({
      preview = {
        renderer = "mermaid.js", -- または "beautiful-mermaid"
        theme = "default",       -- dark にするなら "dark"
      },
    })
  end,
}
