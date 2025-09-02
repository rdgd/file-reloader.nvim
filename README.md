# file-reloader.nvim

A modern, efficient Neovim plugin for automatic file change detection and hot buffer/window reloading.

## Features

- **Multiple Detection Methods**: Uses file system polling, focus events, and cursor events for comprehensive coverage
- **Smart Notifications**: Informative notifications when files are reloaded or when external changes are detected
- **Configurable**: Fully customizable polling intervals, notifications, and keymaps
- **Efficient**: Uses native libuv file system polling with debouncing to minimize performance impact
- **Buffer-aware**: Per-buffer file watchers with automatic cleanup
- **Timer fallback**: Background timer ensures files are checked even during extended idle periods

## Installation

### Using lazy.nvim

```lua
{
  dir = "~/file-reloader.nvim", -- Local development path
  name = "file-reloader.nvim",
  config = function()
    require('file-reloader').setup({
      -- Your configuration here (optional)
    })
  end,
  lazy = false,
  priority = 1000,
}
```

### Using packer.nvim

```lua
use {
  '~/file-reloader.nvim', -- Local development path
  config = function()
    require('file-reloader').setup()
  end
}
```

## Configuration

Default configuration:

```lua
require('file-reloader').setup({
  -- Vim options for auto-reloading
  autoread = true,          -- Enable automatic file reading
  backup = false,           -- Disable backup files
  writebackup = false,      -- Disable write backup
  swapfile = false,         -- Disable swap files
  
  -- File watching settings
  updatetime = 1000,        -- Vim's updatetime in milliseconds
  poll_interval = 1000,     -- File polling interval in milliseconds
  timer_interval = 2000,    -- Background timer interval in milliseconds
  debounce_time = 1000000000, -- Cursor event debounce time in nanoseconds
  
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
```

## Usage

Once installed and configured, the plugin works automatically:

- Files are monitored when opened in buffers
- External changes trigger automatic reloads
- Notifications inform you when files are reloaded
- Use the refresh keymap (`<leader>r` by default) to manually check for changes

## API

The plugin exposes several functions for advanced usage:

```lua
local file_reloader = require('file-reloader')

-- Setup the plugin with custom options
file_reloader.setup(opts)

-- Manually refresh all files
file_reloader.refresh()

-- Get status information
local status = file_reloader.status()
print("Active watchers: " .. status.active_watchers)

-- Cleanup (usually not needed)
file_reloader.cleanup()
```

## How It Works

The plugin uses a multi-layered approach for reliable file change detection:

1. **Native libuv File System Polling**: Each buffer gets its own file watcher using `vim.loop.new_fs_poll()`
2. **Event-Based Detection**: Triggers on `FocusGained`, `BufEnter`, and `WinEnter` events
3. **Cursor-Based Detection**: Debounced checks on `CursorHold` and `CursorHoldI` events
4. **Timer Fallback**: Background timer ensures files are checked during extended idle periods

This combination ensures that file changes are detected quickly and reliably while minimizing performance impact.

## Requirements

- Neovim 0.7+ (for native libuv support)
- No external dependencies

## License

MIT License