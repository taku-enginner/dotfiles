return {
  {
    'kevinhwang91/nvim-bqf',
    ft = 'qf',
    config = function()
      require('bqf').setup({
        -- プレビューウィンドウを自動で有効にする
        auto_enable = true,
      })
    end,
  },
}
