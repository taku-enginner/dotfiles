return {
  'akinsho/bufferline.nvim',
  version = "*",
  dependencies = 'nvim-tree/nvim-web-devicons',
  config = function()
    require("bufferline").setup{}
    vim.keymap.set("n", "<C-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "前のバッファへ" })
    vim.keymap.set("n", "<C-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "次のバッファへ" })

  end,
}

