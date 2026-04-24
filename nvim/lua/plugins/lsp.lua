vim.fn.jobstart({"bash", "-c", "if command -v ruby >/dev/null 2>&1 && command -v gem >/dev/null 2>&1; then gem install solargraph; fi"})

return {
  {
    "hrsh7th/nvim-cmp",
    -- `dependencies`は、nvim-cmpが機能するために必要な追加プラグインです
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- LSPからの補完
      "hrsh7th/cmp-buffer",   -- 開いているバッファ内の単語からの補完
      "hrsh7th/cmp-path",     -- ファイルパスの補完
      "zbirenbaum/copilot-cmp", -- これがCopilotからの補完を提供します
      -- スニペットを使いたい場合は以下のコメントを外します
      -- "L3MON4D3/LuaSnip",
      -- "saadparwaiz1/cmp_luasnip",
    },
    -- `config`関数内でプラグインのセットアップを行います
    config = function()
      local cmp = require('cmp')
      local cmp_select = { behavior = cmp.SelectBehavior.Select }

      cmp.setup({
        -- スニペットの設定（もし使う場合）
        -- snippet = {
        --   expand = function(args)
        --     require('luasnip').lsp_expand(args.body)
        --   end,
        -- },

        -- 【重要】キーマッピングの設定
        mapping = cmp.mapping.preset.insert({
          -- 候補を選択
          ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
          ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),

          -- 補完を確定
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Enterキーで確定
          ['<C-Space>'] = cmp.mapping.complete(), -- 手動で補完を開始

          -- 補完ウィンドウを閉じる
          ['<C-e>'] = cmp.mapping.abort(),
        }),

        -- 補完ソース（どこから候補を持ってくるか）の設定
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "copilot" },
          -- { name = "luasnip" }, -- スニペットを使う場合はコメントを外す
          { name = "buffer" },
          { name = "path" },
        }),
      }) -- cmp.setup
    end,
  },
  -- (1) Mason.nvim プラグイン
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    config = function()
      require("mason").setup()
    end,
  },

  -- (2) mason-lspconfig.nvim プラグイン
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
    },
    config = function()
      require("mason-lspconfig").setup({
        -- ここに自動インストールしたいLSPサーバーを記述
        ensure_installed = {
          "lua_ls",
          "html",
          "cssls",
          "jsonls",
          "ts_ls",
          "jdtls",
        },
      })
    end,
  },

  -- (3) nvim-lspconfig プラグイン TODO: lspconfigがエラー吐いてたから使用箇所でコメントアウトしている
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp", -- nvim-cmpとの連携用
      "j-hui/fidget.nvim", -- LSPの進捗状況表示用
    },

    config = function()
    --local lspconfig = require("lspconfig")
    local mason_lspconfig = require("mason-lspconfig")

    -- mason-lspconfig: サーバーのインストールを保証
    mason_lspconfig.setup({
      ensure_installed = {
        "lua_ls",
        "html",
        "cssls",
        "jsonls",
        "ts_ls",
        "perlnavigator",
        "pyright",
        "jdtls",
      },
    })

    -- LSP設定（nvim-cmp連携）
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

    -- lua_ls の特別な設定
    --lspconfig.lua_ls.setup({
      --capabilities = capabilities,
      --settings = {
        --Lua = {
          --diagnostics = {
            --globals = { "vim" },
          --},
        --},
      --},
    --})

      -- その他のサーバーはデフォルト設定
      --for _, server in ipairs({ "html", "cssls", "jsonls", "ts_ls" }) do
        --lspconfig[server].setup({ capabilities = capabilities })
      --end
    end,
  },
}
