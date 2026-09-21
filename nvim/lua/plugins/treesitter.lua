-- mermaid.nvim / noice.nvim の依存として保持している。
-- highlight / fold は有効化していない(configs.setup() を呼んでいないため)。
-- branch = 'master' は必須: main branch は破壊的変更が入っている。
return {
  "nvim-treesitter/nvim-treesitter",
  branch = 'master',
  build = ":TSUpdate",
}
