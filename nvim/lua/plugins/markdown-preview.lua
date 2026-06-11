return {
  "iamcco/markdown-preview.nvim",
  ft = { "markdown" },
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
  -- プリビルドバイナリを取得（yarn 不要）
  build = function()
    require("lazy").load({ plugins = { "markdown-preview.nvim" } })
    vim.fn["mkdp#util#install"]()
  end,
  init = function()
    -- WSL: wslview/デスクトップ無しで xdg-open が効かないため explorer.exe で Windows 既定ブラウザを開く
    vim.g.mkdp_browser = "explorer.exe"
    -- ブラウザを自動で開く
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
  end,
  keys = {
    { mode = "n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdownをブラウザでプレビュー(トグル)" },
  },
}
