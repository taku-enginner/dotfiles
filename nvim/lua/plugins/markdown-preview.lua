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
      -- プラグインの node 実装は WSL を検出すると cmd.exe で start する(opener.js)。
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
    -- 0: バッファが hidden になっても閉じない（BufHidden での自動クローズを無効化）。
    -- タブ切り替えではバッファがウィンドウに残るのでプレビューが共存する。
    vim.g.mkdp_auto_close = 0

    -- 片付けは「バッファが実際に削除されたとき」(BufDelete/BufWipeout) に行う。
    --   ファイルを閉じる(":bd"/":bw") → 発火 → プレビューを閉じる。
    --   バッファ切り替え(bufferline の :bnext/:bprev/CycleNext 等) → バッファは
    --     listed のまま hidden になるだけで削除されない → 発火しない → 共存する。
    --   nvim 終了(":qa") → プラグインの VimLeave が stop_server で全プレビューを閉じる。
    -- ※ BufWinLeave は「バッファがウィンドウから外れたとき」発火し、bufferline の
    --   バッファ切り替え(1ウィンドウ内でバッファ置換)でも発火してしまうため使わない。
    -- グローバルに1個だけ張る。MarkdownPreviewToggleBool でプレビュー起動中のバッファに限定するので
    -- filetype 判定もバッファローカル autocmd も不要（FileType ネストだと lazy ロードで重複登録される）。
    -- 注意: 発火時点ではカレントが既に別バッファのことがある（cur != <abuf>）。
    -- preview_close() は bufnr('%') の close_page を送るため、素で呼ぶと別プレビューを誤爆する。
    -- nvim_buf_call で対象バッファ(a.buf)を一時的にカレントにしてから閉じる
    -- （BufDelete/BufWipeout 発火時点では a.buf はまだ valid）。
    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
      group = vim.api.nvim_create_augroup("MkdpCloseOnDelete", { clear = true }),
      callback = function(a)
        if not vim.api.nvim_buf_is_valid(a.buf) then
          return
        end
        local ok, flag = pcall(function()
          return vim.b[a.buf].MarkdownPreviewToggleBool
        end)
        if ok and flag then
          pcall(function()
            vim.api.nvim_buf_call(a.buf, function()
              vim.fn["mkdp#rpc#preview_close"]()
            end)
          end)
        end
      end,
    })
  end,
  keys = {
    { mode = "n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdownをブラウザでプレビュー(トグル)" },
  },
}
