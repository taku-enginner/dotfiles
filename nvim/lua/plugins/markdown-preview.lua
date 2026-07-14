return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  -- ブラウザプレビュー用サーバーのインストール
  -- lazy.nvim はビルド時にプラグイン未ロードのため、先にロードしないと
  -- autoload 関数 mkdp#util#install が E117 になる
  build = function()
    require("lazy").load({ plugins = { "markdown-preview.nvim" } })
    vim.fn["mkdp#util#install"]()
  end,
  keys = {
    { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown Preview Toggle", ft = "markdown" },
  },
}
