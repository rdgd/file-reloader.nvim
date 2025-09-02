local M = {}

-- Default configuration
M.config = {
  -- Vim options for auto-reloading
  autoread = true,
  backup = false,
  writebackup = false,
  swapfile = false,
  
  -- File watching settings
  updatetime = 1000,
  poll_interval = 1000,
  timer_interval = 2000,
  debounce_time = 1000000000, -- 1 second in nanoseconds
  
  -- Notifications
  notifications = {
    enabled = true,
    timeout = 2000,
    warn_timeout = 4000,
  },
  
  -- Keymaps
  keymaps = {
    enabled = true,
    refresh = '<leader>r',
  },
}

-- Store active file watchers and state
local file_watchers = {}
local last_cursor_check = 0
local autorefresh_group = nil
local global_timer = nil

-- Function to check for file changes
local function check_file_changes()
  if vim.fn.mode() ~= 'c' then
    vim.cmd.checktime()
  end
end

-- Set up timer-based periodic checking
local function setup_file_timer()
  local timer = vim.loop.new_timer()
  if timer then
    timer:start(M.config.timer_interval, M.config.timer_interval, vim.schedule_wrap(function()
      -- Only check if we're in a normal buffer and not in command mode
      if vim.api.nvim_get_mode().mode ~= 'c' and vim.bo.buftype == '' then
        check_file_changes()
      end
    end))
    return timer
  end
end

-- Set up file watcher for a specific buffer
local function setup_buffer_watcher(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == '' or vim.bo[bufnr].buftype ~= '' then
    return
  end
  
  -- Clean up existing watcher for this buffer
  if file_watchers[bufnr] then
    file_watchers[bufnr]:stop()
  end
  
  -- Set up new file watcher using native libuv
  file_watchers[bufnr] = vim.loop.new_fs_poll()
  if file_watchers[bufnr] then
    file_watchers[bufnr]:start(filepath, M.config.poll_interval, vim.schedule_wrap(function(err, prev, curr)
      if not err and curr and prev then
        -- Check if file was actually modified
        if curr.mtime.sec ~= prev.mtime.sec or curr.mtime.nsec ~= prev.mtime.nsec then
          -- Only reload if buffer is still valid and file exists
          if vim.api.nvim_buf_is_valid(bufnr) and vim.fn.filereadable(filepath) == 1 then
            vim.cmd.checktime()
          end
        end
      end
    end))
  end
end

-- Clean up file watcher for a buffer
local function cleanup_buffer_watcher(bufnr)
  if file_watchers[bufnr] then
    file_watchers[bufnr]:stop()
    file_watchers[bufnr] = nil
  end
end

-- Set up all autocmds
local function setup_autocmds()
  autorefresh_group = vim.api.nvim_create_augroup("FileReloader", { clear = true })

  -- Primary file watching - triggers on focus and buffer events
  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "WinEnter" }, {
    group = autorefresh_group,
    pattern = "*",
    callback = check_file_changes,
    desc = "Check for external file changes on focus/buffer enter"
  })

  -- Improved cursor-based detection with debouncing
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = autorefresh_group,
    pattern = "*",
    callback = function()
      local current_time = vim.loop.hrtime()
      -- Debounce: only check if it's been more than configured time since last check
      if current_time - last_cursor_check > M.config.debounce_time then
        last_cursor_check = current_time
        check_file_changes()
      end
    end,
    desc = "Debounced periodic check for external file changes"
  })

  -- Handle file changes with enhanced notifications
  if M.config.notifications.enabled then
    vim.api.nvim_create_autocmd({ "FileChangedShellPost" }, {
      group = autorefresh_group,
      pattern = "*",
      callback = function()
        local filename = vim.fn.expand('%:t')
        local filepath = vim.fn.expand('%:p')
        local filetime = vim.fn.strftime('%H:%M:%S', vim.fn.getftime(filepath))
        vim.notify(
          string.format("📄 '%s' reloaded (modified at %s)", filename, filetime), 
          vim.log.levels.INFO, 
          { 
            title = "File Auto-Reloaded",
            timeout = M.config.notifications.timeout
          }
        )
      end,
      desc = "Notify when file is automatically reloaded from disk"
    })

    -- Handle file changes that need user confirmation
    vim.api.nvim_create_autocmd({ "FileChangedShell" }, {
      group = autorefresh_group,
      pattern = "*",
      callback = function()
        local filename = vim.fn.expand('%:t')
        vim.notify(
          string.format("⚠️ '%s' changed externally - reload pending", filename), 
          vim.log.levels.WARN, 
          { 
            title = "External Changes Detected",
            timeout = M.config.notifications.warn_timeout
          }
        )
      end,
      desc = "Warn when file changed externally but awaiting reload confirmation"
    })

    -- Enhanced config reload notification
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = autorefresh_group,
      pattern = { "*.lua" },
      callback = function()
        local filename = vim.fn.expand('%:t')
        if filename == "init.lua" or vim.fn.expand('%:p'):find("nvim/lua") then
          vim.notify(
            "Neovim config saved. Restart to apply changes.", 
            vim.log.levels.INFO, 
            { 
              title = "Config Update",
              timeout = M.config.notifications.warn_timeout
            }
          )
        end
      end,
      desc = "Notify when Neovim config files are saved"
    })
  end

  -- Set up file watcher for new buffers
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    group = autorefresh_group,
    pattern = "*",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      setup_buffer_watcher(bufnr)
    end,
    desc = "Set up file watcher for new buffers"
  })

  -- Clean up file watchers when buffers are deleted
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = autorefresh_group,
    pattern = "*",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      cleanup_buffer_watcher(bufnr)
    end,
    desc = "Clean up file watchers for deleted buffers"
  })

  -- Initialize auto-refresh on startup
  vim.api.nvim_create_autocmd({ "VimEnter" }, {
    group = autorefresh_group,
    pattern = "*",
    callback = function()
      -- Check all buffers for changes on startup
      vim.cmd.checktime()
      
      -- Start global timer for backup checking
      global_timer = setup_file_timer()
      
      -- Set up watchers for all current buffers
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          setup_buffer_watcher(bufnr)
        end
      end
      
      if M.config.notifications.enabled then
        vim.notify(
          "Enhanced file watching system active", 
          vim.log.levels.INFO, 
          { 
            title = "File Reloader",
            timeout = M.config.notifications.timeout
          }
        )
      end
    end,
    desc = "Initialize enhanced auto-refresh system with file watchers"
  })
end

-- Set up vim options
local function setup_vim_options()
  vim.opt.autoread = M.config.autoread
  vim.opt.backup = M.config.backup
  vim.opt.writebackup = M.config.writebackup
  vim.opt.swapfile = M.config.swapfile
  vim.opt.updatetime = M.config.updatetime
end

-- Set up keymaps
local function setup_keymaps()
  if M.config.keymaps.enabled then
    vim.keymap.set('n', M.config.keymaps.refresh, ':checktime<CR>', { 
      desc = 'Refresh file from disk', 
      noremap = true 
    })
  end
end

-- Setup function
function M.setup(opts)
  -- Merge user config with defaults
  if opts then
    M.config = vim.tbl_deep_extend('force', M.config, opts)
  end
  
  -- Set up all components
  setup_vim_options()
  setup_keymaps()
  setup_autocmds()
end

-- Cleanup function
function M.cleanup()
  -- Stop global timer
  if global_timer then
    global_timer:stop()
    global_timer:close()
    global_timer = nil
  end
  
  -- Clean up all file watchers
  for bufnr, watcher in pairs(file_watchers) do
    watcher:stop()
    file_watchers[bufnr] = nil
  end
  
  -- Clear autocmd group
  if autorefresh_group then
    vim.api.nvim_del_augroup_by_id(autorefresh_group)
  end
end

-- Manual refresh function
function M.refresh()
  check_file_changes()
end

-- Get status of file watchers
function M.status()
  local active_watchers = 0
  for _ in pairs(file_watchers) do
    active_watchers = active_watchers + 1
  end
  
  return {
    active_watchers = active_watchers,
    global_timer_active = global_timer ~= nil,
    autorefresh_group_id = autorefresh_group,
  }
end

return M