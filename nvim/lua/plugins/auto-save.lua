return {
  "Pocco81/auto-save.nvim",
  event = "VeryLazy",
  config = function()
    require("auto-save").setup {
      enabled = true,
      execution_message = {
        message = function() return "AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S") end,
        dim = 0.18,
        cleaning_interval = 1250,
      },
      trigger_events = { "InsertLeave", "TextChanged" },
      conditions = {
        exists = true,
        filename_is_not = {},
        filetype_is_not = { "gitcommit", "gitrebase", "svn", "hgcommit" },
        modifiable = true,
      },
      write_all_buffers = false,
      debounce_delay = 135,
      callbacks = {
        before_asserting_save = function() end,
        after_asserting_save = function() end,
        before_saving = function() end,
        after_saving = function() end,
        when_idle = function() end,
      },
    }
  end,
}
