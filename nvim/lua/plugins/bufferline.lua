-- バッファ移動キーは config/keymaps.lua の <leader>j / <leader>k に一本化している
return {
  'akinsho/bufferline.nvim',
  version = "*",
  event = "VeryLazy",
  dependencies = 'nvim-tree/nvim-web-devicons',
  opts = {},
}
