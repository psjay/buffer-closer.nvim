# Buffer Closer

A Neovim plugin that provides a convenient way to close buffers, windows, or exit Vim with a single keypress.

## Features

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

1. Close the current buffer if there are multiple buffers open
2. Exit Vim if it's the last buffer

## License

[MIT License](LICENSE)
