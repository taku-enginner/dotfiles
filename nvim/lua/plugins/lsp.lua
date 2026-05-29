vim.fn.jobstart({"bash", "-c", "if command -v ruby >/dev/null 2>&1 && command -v gem >/dev/null 2>&1; then gem install solargraph; fi"})

-- nvim-cmp 本体の定義は plugins/cmp.lua に一本化している
return {
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
