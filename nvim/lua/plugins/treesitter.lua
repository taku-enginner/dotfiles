-- mermaid.nvim / noice.nvim の依存として保持している。
-- highlight / fold は有効化していない(configs.setup() を呼んでいないため)。
-- branch = 'master' は必須: main branch は破壊的変更が入っている。
-- master は Neovim 0.12 非対応なので 0.12 以上では読み込まない(mermaid のハイライトは
-- ~/.local/share/nvim/site/parser/mermaid.so で動く)。
return {
  "nvim-treesitter/nvim-treesitter",
  cond = vim.fn.has("nvim-0.12") == 0,
  branch = 'master',
  build = ":TSUpdate",
}
