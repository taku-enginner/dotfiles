return {
  "nvimdev/lspsaga.nvim",
  event = "LspAttach",
  dependencies = { "nvim-tree/nvim-web-devicons"  -- optional
  },
  opts = {
    vim.keymap.set("n", "gh", "<cmd>Lspsaga lsp_finder<CR>", { silent = true }),
    vim.keymap.set("n", "gD", "<cmd>Lspsaga peek_definition<CR>", { silent = true }),
    vim.keymap.set("n", "gd", "<cmd>Lspsaga goto_definition<CR>", { silent = true }),
    vim.keymap.set("n", "gr", "<cmd>Lspsaga rename<CR>", { silent = true }),
    vim.keymap.set("n", "gp", "<cmd>Lspsaga peek_type_definition<CR>", { silent = true }),
    vim.keymap.set("n", "gt", "<cmd>Lspsaga goto_type_definition<CR>", { silent = true }),
    vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", { silent = true }),
    vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { silent = true }),
    vim.keymap.set("n", "<leader>sl", "<cmd>Lspsaga show_line_diagnostics<CR>", { silent = true }),
    vim.keymap.set("n", "<leader>sc", "<cmd>Lspsaga show_cursor_diagnostics<CR>", { silent = true }),
    vim.keymap.set("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { silent = true }),
    vim.keymap.set("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>", { silent = true }),
    vim.keymap.set("n", "<leader>o", "<cmd>Lspsaga outline<CR>", { silent = true }),
  }
}
