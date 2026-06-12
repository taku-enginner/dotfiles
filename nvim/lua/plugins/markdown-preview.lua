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
    if vim.fn.has("wsl") == 1 then
      -- WSLローカル: explorer.exe で Windows 既定ブラウザを開く
      vim.g.mkdp_browser = "explorer.exe"
    else
      -- リモート(ssh): 自前でブラウザを開けないので URL を echo し、
      -- ローカルへ ssh -L 8765:localhost:8765 で転送して localhost で開く
      vim.g.mkdp_echo_preview_url = 1
      -- ヘッドレスでの xdg-open 失敗(processTicksAndRejections)抑止: 起動を no-op に
      vim.g.mkdp_browser = "true"
    end
    -- ポート固定（ssh -L の転送先を予測可能にする）
    vim.g.mkdp_port = "8765"
    -- ブラウザを自動で開く
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
  end,
  keys = {
    { mode = "n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdownをブラウザでプレビュー(トグル)" },
  },
}
