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
      -- プラグインの node 実装は cmd.exe をベア名で spawn する(opener.js)。
      -- シェル PATH から Windows 側が外されていると cmd.exe が見つからず
      -- 「Can not open browser by using cmd.exe command」で失敗する。
      -- インタラクティブシェルの PATH は汚さず、nvim の env にだけ System32 を補う。
      local sys32 = "/mnt/c/Windows/System32"
      if vim.fn.isdirectory(sys32) == 1 and not vim.env.PATH:find(sys32, 1, true) then
        vim.env.PATH = vim.env.PATH .. ":" .. sys32
      end
    else
      -- リモート(ssh): 自前でブラウザを開けないので URL を echo し、
      -- ローカルへ ssh -L 8765:localhost:8765 で転送して localhost で開く
      vim.g.mkdp_echo_preview_url = 1
      -- ヘッドレスでの xdg-open 失敗(processTicksAndRejections)抑止: 起動を no-op に
      vim.g.mkdp_browser = "true"
      -- ポート固定（ssh -L の転送先を予測可能にする）。
      -- WSLローカルでは固定しない: ssh の LocalForward 8765 と衝突し EADDRINUSE になる
      vim.g.mkdp_port = "8765"
    end
    -- ブラウザを自動で開く
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
    -- コンテンツ幅をウィンドウに追従させる（同梱 page.css の #page-ctn max-width:900px を上書き）
    vim.g.mkdp_markdown_css = vim.fn.stdpath("config") .. "/markdown-preview.css"
  end,
  keys = {
    { mode = "n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdownをブラウザでプレビュー(トグル)" },
  },
}
