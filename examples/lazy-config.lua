-- Example configuration for lazy.nvim
-- Add this to your lazy.nvim plugin table

{
  -- For local development (replace with actual git repo when published)
  dir = vim.fn.expand("~/file-reloader.nvim"),
  name = "file-reloader.nvim",
  
  -- For published plugin (uncomment when available):
  -- "your-username/file-reloader.nvim",
  
  lazy = false,
  priority = 900, -- Load after notification plugins but before most others
  
  config = function()
    require('file-reloader').setup({
      -- Vim options for auto-reloading
      autoread = true,
      backup = false,
      writebackup = false,
      swapfile = false,
      
      -- File watching settings
      updatetime = 1000,        -- Vim's updatetime in milliseconds
      poll_interval = 1000,     -- File polling interval in milliseconds
      timer_interval = 2000,    -- Background timer interval in milliseconds
      
      -- Notifications
      notifications = {
        enabled = true,         -- Enable notifications
        timeout = 2000,         -- Info notification timeout
        warn_timeout = 4000,    -- Warning notification timeout
      },
      
      -- Keymaps
      keymaps = {
        enabled = true,         -- Enable default keymaps
        refresh = '<leader>r',  -- Manual refresh keymap
      },
    })
  end,
}