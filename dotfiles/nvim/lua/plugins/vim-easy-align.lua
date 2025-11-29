return {
  "junegunn/vim-easy-align",
  cmd = "EasyAlign",
  keys = {
    -- ノーマルモード
    { "ga", function() vim.cmd("EasyAlign") end, mode = "n", desc = "Start EasyAlign" },
    -- ビジュアルモード
    { "ga", "<Plug>(EasyAlign)", mode = "x", desc = "Start EasyAlign" },
  },
}
