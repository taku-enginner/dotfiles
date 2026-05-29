return {
  -- メインの telescope.nvim の設定ブロック
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  cmd = "Telescope",
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- live-grep-args を依存関係として追加
    'nvim-telescope/telescope-live-grep-args.nvim',
  },
  -- キー押下で遅延読み込み
  keys = {
    { '<leader>ff', function() require('telescope.builtin').find_files() end, desc = 'Telescope find files' },
    { '<leader>fg', function() require('telescope.builtin').live_grep() end, desc = 'Telescope live grep' },
    { '<leader>fa', function() require('telescope').extensions.live_grep_args.live_grep_args() end, desc = 'Live Grep (with args)' },
  },
  config = function()
    -- 拡張機能をロード
    require("telescope").load_extension("live_grep_args")
  end
}
