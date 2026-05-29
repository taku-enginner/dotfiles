return {
  'ethanholz/nvim-lastplace',
  -- lastplace.nvim の設定
  opts = {
    lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit", -- 無視するファイルタイプ
    lastplace_open_cmd = "",                               -- 最後に開いていた場所に戻るコマンド（デフォルトは ""）
  },
  -- プラグインが読み込まれるタイミングを指定 (optional)
  -- Lastplaceは、Nvimが起動してすぐに実行される必要があるため、
  -- 読み込みの遅延設定は特に必要ありません（イベント指定は省略可）。
  -- event = "BufReadPost",
}

