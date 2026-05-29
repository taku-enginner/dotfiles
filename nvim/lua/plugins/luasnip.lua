return {
  "L3MON4D3/LuaSnip",
  version = "v2.*",
  build = "make install_jsregexp",
  dependencies = {
    "benfowler/telescope-luasnip.nvim", -- Telescope拡張を追加
  },
  config = function()
    -- 1. VS Code 形式のスニペットを読み込む(nvim 設定ディレクトリ配下の snippets/)
    require("luasnip.loaders.from_vscode").lazy_load({
      paths = { vim.fn.stdpath("config") .. "/snippets" },
      watch_files = true,
    })

    -- 2. Telescope 拡張をロード
    local status_ok, telescope = pcall(require, "telescope")
    if status_ok then
      telescope.load_extension("luasnip")
    end

    -- <leader>sl でスニペット一覧を呼び出す
    vim.keymap.set("n", "<leader>sl", function()
      require("telescope").extensions.luasnip.luasnip(
        require("telescope.themes").get_dropdown({
          layout_config = {
            width = 0.95,
            height = 0.6,
          },
        })
      )
    end, { desc = "Snippet List" })
  end,
}
