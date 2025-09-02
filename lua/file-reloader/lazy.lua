-- Lazy.nvim plugin specification for file-reloader.nvim
-- This makes it easy to integrate with lazy.nvim plugin manager

return {
  name = "file-reloader.nvim",
  
  -- Plugin configuration
  opts = {
    -- Default options - can be overridden by user
    autoread = true,
    backup = false,
    writebackup = false,
    swapfile = false,
    updatetime = 1000,
    poll_interval = 1000,
    timer_interval = 2000,
    notifications = {
      enabled = true,
      timeout = 2000,
      warn_timeout = 4000,
    },
    keymaps = {
      enabled = true,
      refresh = '<leader>r',
    },
  },
  
  -- Setup function called by lazy.nvim
  config = function(_, opts)
    require('file-reloader').setup(opts)
  end,
  
  -- Load on startup
  lazy = false,
  priority = 1000,
}