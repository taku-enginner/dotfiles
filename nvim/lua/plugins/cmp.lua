return {
  -- 補完フレームワーク本体
  'hrsh7th/nvim-cmp',
  event = "InsertEnter",
  dependencies = {
    -- 必須：LSP補完、バッファ補完
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    -- ファイルパス補完
    'hrsh7th/cmp-path',
    'petertriho/cmp-git',
  },
  config = function()
    local cmp = require('cmp')
    local select_opts = { behavior = cmp.SelectBehavior.Select }

    cmp.setup({
      snippet = {
        -- 組み込み vim.snippet で LSP 由来のスニペットを展開(luasnip 廃止)
        expand = function(args)
          vim.snippet.expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ['<Tab>'] = cmp.mapping(function(fallback)
          -- 補完候補があれば次へ、スニペットのジャンプ先があれば移動
          if cmp.visible() then
            cmp.select_next_item(select_opts)
          elseif vim.snippet.active({ direction = 1 }) then
            vim.snippet.jump(1)
          else
            fallback()
          end
        end, { 'i', 's' }),
      }),
      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'path' },
      }),
    })

    cmp.setup.filetype('gitcommit', {
      sources = cmp.config.sources({
        { name = 'git' },  -- cmp-gitのソースを最優先で有効化
        { name = 'buffer' },
      })
    })
  end,
}
