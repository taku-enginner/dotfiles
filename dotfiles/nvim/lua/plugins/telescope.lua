return {
  -- (A) メインの telescope.nvim の設定ブロック
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- (B) live-grep-args を依存関係として追加
    'nvim-telescope/telescope-live-grep-args.nvim',
  },
  config = function()
    -- 拡張機能をロード
    require("telescope").load_extension("live_grep_args")

    local builtin = require('telescope.builtin')

    -- 標準のキーマッピング
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })

    -- (C) live_grep_args 用のキーマッピングを追加（<leader>faなど）
    vim.keymap.set('n', '<leader>fa', function()
      -- 拡張機能が提供するピッカーを呼び出す
      require('telescope').extensions.live_grep_args.live_grep_args()
    end, { desc = "Live Grep (with args)" })

  end
}
