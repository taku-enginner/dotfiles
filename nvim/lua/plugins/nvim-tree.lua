-- ファイルツリー。トグルは config/keymaps.lua の <leader>e
return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- アイコン表示用 (オプション)
  },
  opts = {
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
    actions = {
      open_file = {
        -- ファイルを開いたらツリーを閉じる
        quit_on_open = true,
      },
    },
  },
}
