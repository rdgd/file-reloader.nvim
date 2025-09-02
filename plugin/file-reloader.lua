-- Auto-initialize file-reloader if not already set up
-- This ensures the plugin works even without explicit setup() call

if vim.g.file_reloader_loaded then
  return
end

vim.g.file_reloader_loaded = true

-- Set up the plugin with default configuration
-- Users can still call setup() later to override these defaults
require('file-reloader').setup()

-- Create user commands for manual control
vim.api.nvim_create_user_command('FileReloaderRefresh', function()
  require('file-reloader').refresh()
end, {
  desc = 'Manually refresh all files from disk'
})

vim.api.nvim_create_user_command('FileReloaderStatus', function()
  local status = require('file-reloader').status()
  print(string.format(
    'File Reloader Status:\n' ..
    '  Active watchers: %d\n' ..
    '  Global timer active: %s\n' ..
    '  Autorefresh group ID: %s',
    status.active_watchers,
    status.global_timer_active and 'yes' or 'no',
    status.autorefresh_group_id or 'none'
  ))
end, {
  desc = 'Show file reloader status information'
})

vim.api.nvim_create_user_command('FileReloaderCleanup', function()
  require('file-reloader').cleanup()
  print('File reloader cleaned up')
end, {
  desc = 'Clean up file reloader resources'
})