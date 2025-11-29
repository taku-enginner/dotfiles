return {
  "rhysd/git-messenger.vim",
  event = "VeryLazy",
  config = function()
    vim.g.git_messenger_no_default_mappings = 1
    vim.g.git_messenger_floating_win_opts = {
      border = "rounded",
    }
    vim.keymap.set("n", "<leader>gm", "<cmd>GitMessenger<CR>", { desc = "Git Messenger" })
  end,
}
