# Changelog

All notable changes to file-reloader.nvim will be documented in this file.

## [1.0.0] - 2025-09-02

### Added
- Initial release of file-reloader.nvim plugin
- Multi-layered file change detection using:
  - Native libuv file system polling per buffer
  - Focus-based detection (FocusGained, BufEnter, WinEnter)
  - Cursor-based detection with debouncing
  - Background timer fallback for extended idle periods
- Smart notifications for file reloads and external changes
- Configurable polling intervals and notification settings
- Automatic vim option configuration (autoread, backup, etc.)
- Per-buffer file watchers with automatic cleanup
- User commands for manual control (FileReloaderRefresh, FileReloaderStatus, FileReloaderCleanup)
- Comprehensive documentation and help files
- Example configurations for lazy.nvim
- Full API for programmatic control

### Features
- Efficient native libuv implementation
- Debounced cursor events to prevent excessive checking
- Automatic cleanup of file watchers when buffers are deleted
- Informative notifications with timestamps
- Configurable keymaps (default: `<leader>r` for manual refresh)
- Status reporting for debugging and monitoring
- Support for both lazy.nvim and packer.nvim plugin managers

### Technical Details
- Uses `vim.loop.new_fs_poll()` for efficient file system monitoring
- Implements smart debouncing to minimize performance impact
- Handles edge cases like command mode, empty buffers, and special buffer types
- Provides graceful fallback mechanisms for reliable operation