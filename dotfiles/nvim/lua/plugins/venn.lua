-- plugins/venn.lua
return {
  "jbyuki/venn.nvim",
  lazy = false, -- 起動時に読み込む（必要に応じて true にしてイベントで遅延読み込みも可）
  config = function()
    -- オプション: シンプルなトグルマッピング
    vim.api.nvim_set_keymap("n", "<leader>v", ":lua Toggle_venn()<CR>", { noremap = true, silent = true })

    function Toggle_venn()
      local venn_enabled = vim.b.venn_enabled or false
      if venn_enabled then
        vim.cmd [[setlocal ve=]]
        vim.cmd [[mapclear <buffer>]]
        vim.b.venn_enabled = false
      else
        vim.b.venn_enabled = true
        vim.cmd [[setlocal ve=all]]
        -- マッピング：矢印キーで枠線を描く
        vim.api.nvim_buf_set_keymap(0, "n", "J", "<C-v>j:VBox<CR>", {})
        vim.api.nvim_buf_set_keymap(0, "n", "K", "<C-v>k:VBox<CR>", {})
        vim.api.nvim_buf_set_keymap(0, "n", "L", "<C-v>l:VBox<CR>", {})
        vim.api.nvim_buf_set_keymap(0, "n", "H", "<C-v>h:VBox<CR>", {})
      end
    end
  end,
}

