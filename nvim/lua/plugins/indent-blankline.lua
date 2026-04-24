return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",

  -- このプラグインの読み込みを Vim の起動完了後まで遅らせる
  -- "VimEnter" はすべての起動処理が終わった後のイベント
  event = "VimEnter",

  opts = {
    indent = {
      highlight = {
        "RainbowRed",
        "RainbowYellow",
        "RainbowBlue",
        "RainbowOrange",
        "RainbowGreen",
        "RainbowViolet",
        "RainbowCyan",
      },
      char = "│", -- インデント文字を明示的に指定（お好みで変更してください）
    },
    scope = { enabled = false },
  },

  -- config関数でハイライトを定義する
  config = function(_, opts)
    -- ハイライトグループを定義
    vim.api.nvim_set_hl(0, "RainbowRed",    { fg = "#E06C75" })
    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" }) -- 色を修正: 元の#E5C07Bなどに戻してください
    vim.api.nvim_set_hl(0, "RainbowBlue",   { fg = "#61AFEF" })
    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
    vim.api.nvim_set_hl(0, "RainbowGreen",  { fg = "#98C379" })
    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
    vim.api.nvim_set_hl(0, "RainbowCyan",   { fg = "#56B6C2" })

    -- プラグインのセットアップを実行
    require("ibl").setup(opts)
  end,
}
