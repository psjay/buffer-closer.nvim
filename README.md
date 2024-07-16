# Buffer Closer

A Neovim plugin that provides a convenient way to close buffers, windows, or exit Vim with the same single keypress.

## Features

https://github.com/user-attachments/assets/067f2503-2e00-4dcc-bc97-d1b74d544b1a

- Close the current window if there are multiple windows opening the current buffer
- Close the current buffer if there are multiple buffers open
- Exit Vim if it's the last buffer
- Automatically sets up key mappings for normal file buffers
- Configurable close key

## Installation

You can install this plugin using your preferred package manager. Here are examples for some popular ones:

### Using [vim-plug](https://github.com/junegunn/vim-plug)

Add the following line to your `init.vim` or `.vimrc`:

```vim
Plug 'psjay/buffer-closer.nvim'
```

Then run `:PlugInstall` in Neovim.

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

Add the following to your Neovim configuration:

```lua
use 'psjay/buffer-closer.nvim'
```

Then run `:PackerSync` in Neovim.

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Add the following to your Neovim configuration:

```lua
{
  'psjay/buffer-closer.nvim',
  config = function()
    require('buffer-closer').setup()
  end
}
```

## Configuration

To configure the plugin, call the `setup` function in your Neovim configuration:

```lua
require('buffer-closer').setup({
  close_key = 'q',
})
```

### Options

- `close_key`: The key to use for closing buffers/windows. Default is 'q'.

## Usage

Once installed and configured, the plugin will automatically set up key mappings for normal file buffers. Press the configured `close_key` (default: 'q') in normal mode to:

1. Close the current window if there are multiple windows opening the current buffer
2. Close the current buffer if there are multiple buffers open
3. Exit Vim if it's the last buffer

## User Commands

Buffer Closer provides two user commands to enable or disable the plugin functionality:

- :`BuffClsDisable`: Temporarily disables the Buffer Closer plugin. When disabled, the close_key will perform its default Neovim action.
- :`BuffClsEnable`: Re-enables the Buffer Closer plugin after it has been disabled.

## License

[MIT License](LICENSE)
