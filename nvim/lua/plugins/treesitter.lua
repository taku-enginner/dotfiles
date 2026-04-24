return {
  -- nvim-treesitterの設定はそのまま残す
  "nvim-treesitter/nvim-treesitter",
  branch = 'master',
  lazy = false,
  build = ":TSUpdate",

  -- 💡 ファイルツリープラグイン nvim-tree の設定を追加
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- アイコン表示用 (オプション)
    },
    config = function()
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = true, -- .fileを表示
        },
        -- 必要に応じてキーマップを設定
        actions = {
          open_file = {
            -- Enterキーでツリーを閉じることなくファイルを開く
            quit_on_open = true,
          }
        }
      })
    end
  }
}
