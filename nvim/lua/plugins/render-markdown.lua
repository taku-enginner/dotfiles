return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = { "markdown" },
  opts = {
    file_types = { "markdown" },
    -- HTMLタグ(detailsなど)の表示設定
    html = {
      enabled = true,
    },
    inline_highlight = {
      enabled = true,
      highlight = 'DiffAdd',
    },
    checkbox = {
      enabled = true,
      checked = {
        icon = '✔',
        scope_highlight = '@comment',
      },
    },
  },
  config = function(_, opts)
    -- render-markdown は markdown の treesitter パーサが必要
    pcall(function()
      require("nvim-treesitter.install").ensure_installed({ "markdown", "markdown_inline" })
    end)
    require("render-markdown").setup(opts)
  end,
}
