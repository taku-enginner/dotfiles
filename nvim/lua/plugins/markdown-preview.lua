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
    -- どのモードでも実プレビュー URL(実ポート込み)を :messages に echo する。
    -- WSLで explorer.exe 自動起動が失敗/見落とされても、その URL を手動で開けば復旧できる。
    vim.g.mkdp_echo_preview_url = 1
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
      -- リモート(ssh): 自前でブラウザを開けないので上記 echo URL を頼りに、
      -- ローカルへ ssh -L 8765:localhost:8765 で転送して localhost で開く
      -- ヘッドレスでの xdg-open 失敗(processTicksAndRejections)抑止: 起動を no-op に
      vim.g.mkdp_browser = "true"
      -- ポート固定（ssh -L の転送先を予測可能にする）。
      -- WSLローカルでは固定しない: ssh の LocalForward 8765 と衝突し EADDRINUSE になる
      vim.g.mkdp_port = "8765"
    end
    -- 自動起動はしない（<leader>mp で手動トグル）
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
    -- コンテンツ幅をウィンドウに追従させる（同梱 page.css の #page-ctn max-width:900px を上書き）
    vim.g.mkdp_markdown_css = vim.fn.stdpath("config") .. "/markdown-preview.css"
  end,
  keys = {
    {
      mode = "n",
      "<leader>mp",
      function()
        if vim.fn.has("wsl") == 1 then
          vim.notify("mkdp: WSLモード — explorer.exe で自動起動。出ない時は :messages の URL を開く", vim.log.levels.INFO)
        else
          vim.notify("mkdp: リモートモード — ssh -L 8765 経由で localhost:8765 を開く(:messages に実URL)", vim.log.levels.INFO)
        end
        vim.cmd("MarkdownPreviewToggle")
      end,
      desc = "Markdownをブラウザでプレビュー(トグル)",
    },
  },
}
