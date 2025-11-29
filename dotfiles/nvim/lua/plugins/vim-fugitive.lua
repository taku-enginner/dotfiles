return{
  "tpope/vim-fugitive",
  event = "VeryLazy",
  config = function()
    -- Optional: Set up any custom keybindings or configurations here
    vim.api.nvim_set_keymap('n', '<leader>gs', ':G<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader>gc', ':G commit<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader>gp', ':G push<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader>gl', ':G log<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader>gd', ':Gdiffsplit<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader>gpl', ':G pull<CR>', { noremap = true, silent = true })
  end
 }

