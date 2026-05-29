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
    -- スニペットエンジン
    'L3MON4D3/LuaSnip',
    -- スニペットの候補を提供する
    'saadparwaiz1/cmp_luasnip',
    'petertriho/cmp-git',
  },
  config = function()
    local cmp = require('cmp')
    local luasnip = require('luasnip')
    local select_opts = { behavior = cmp.SelectBehavior.Select }

    cmp.setup({
      snippet = {
        -- luasnipでスニペットを展開するように設定
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        -- ... (上記と同じキーマップ) ...
        ['<Tab>'] = cmp.mapping(function(fallback)
          -- 候補がある場合、またはスニペットのジャンプポイントがある場合は移動
          if cmp.visible() then
            cmp.select_next_item(select_opts)
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { 'i', 's' }),
      }),
      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' }, -- スニペット候補を追加
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
