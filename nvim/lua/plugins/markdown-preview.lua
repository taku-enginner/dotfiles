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
          vim.cmd("MarkdownPreviewToggle")
          return
        end
        -- リモート(ssh): ポート固定 8765。前回 nvim が SIGKILL 等で落ちて
        -- mkdp の node サーバが 8765 を握ったまま残留すると、次回起動の
        -- server.listen が EADDRINUSE で未捕捉クラッシュ(processTicksAndRejections)し、
        -- listen 成功コールバック内の URL echo が走らず実URLが出ない。
        -- このnvim自身がサーバ稼働中(=トグルでOFFにする)時は掃除しない。
        local running = vim.fn.exists("*mkdp#rpc#get_server_status") == 1
          and vim.fn["mkdp#rpc#get_server_status"]() == 1
        if not running then
          -- 8765 を握る残留 node プロセスだけを落としてから起動(他サービスは触らない)
          vim.fn.system(
            [[for p in $(lsof -ti tcp:8765 2>/dev/null || fuser 8765/tcp 2>/dev/null); do ]]
              .. [[case "$(ps -p "$p" -o comm= 2>/dev/null)" in node*) kill "$p" 2>/dev/null;; esac; done]]
          )
          -- ポート固定なので実URLは確定。node の echo に依存せず直接案内する
          vim.notify(
            ("mkdp: リモートモード — http://localhost:8765/page/%d を ssh -L 8765 経由で開く"):format(vim.fn.bufnr("%")),
            vim.log.levels.INFO
          )
        end
        vim.cmd("MarkdownPreviewToggle")
      end,
      desc = "Markdownをブラウザでプレビュー(トグル)",
    },
  },
}
