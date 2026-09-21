-- nvim-cmp 本体の定義は plugins/cmp.lua に一本化している
return {
  -- LSP サーバーのインストーラ
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {},
  },

  -- mason.nvim の後にロードされる必要がある。
  -- setup() は nvim-lspconfig 側の config で 1 度だけ呼ぶ(二重呼び出し防止)
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
  },

  -- LSP サーバー定義の提供元。実際の起動は mason-lspconfig v2 が
  -- ensure_installed のサーバーを自動 vim.lsp.enable() することで行われる
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp", -- nvim-cmpとの連携用
      "j-hui/fidget.nvim",    -- LSPの進捗状況表示用
    },
    config = function()
      -- 自動 enable より前に設定しておく必要がある

      -- 全サーバーへ nvim-cmp の補完 capabilities を適用
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })

      -- lua_ls: vim グローバルを未定義扱いにしない
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

      require("mason-lspconfig").setup({
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
    end,
  },

  -- LSP の進捗表示(noice 側の lsp.progress は無効にしてこちらへ寄せている)
  {
    "j-hui/fidget.nvim",
    opts = {},
  },
}
