jfind.nvim
==========
A plugin for using jfind as a neovim file fuzzy finder.

Dependencies
------------
 - [jfind](https://github.com/jake-stewart/jfind) (Required)
 - [fdfind](https://github.com/sharkdp/fd) (Recommended as a faster alternative to `find`)

You can install jfind with this one liner. You will need git, cmake, and make.
```
git clone https://github.com/jake-stewart/jfind && cd jfind && cmake -S . -B build && cd build && sudo make install
```

Quickstart
----------

### [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
require("lazy").setup({
    {
        "jake-stewart/jfind.nvim", branch = "1.0",
        keys = {
            {"<c-f>", function()
                local Key = require("jfind.key")
                require("jfind").findFile({
                    formatPaths = true,
                    callback = {
                        [Key.DEFAULT] = vim.cmd.edit,
                        [Key.CTRL_S] = vim.cmd.split,
                        [Key.CTRL_V] = vim.cmd.vsplit,
                    }
                })
            end},
        },
        config = function()
            require("jfind").setup({
                exclude = {
                    ".git", ".idea", ".vscode", ".sass-cache", ".class",
                    "__pycache__", "node_modules", "target", "build",
                    "tmp", "assets", "dist", "public", "*.iml", "*.meta"
                },
                border = "rounded",
                tmux = true,
            });
        end
    },
    ...
```

setup options
-------------
#### tmux
 - a boolean of whether a tmux window is preferred over a neovim window. If tmux is not active, then this value is ignored.
 - Default is `false`.
#### exclude
 - list of strings of files/directories that should be ignored.
 - Entries can contain wildcard matching (e.g. `*.png`).
 - Default is an empty list.
#### border
 - The style of the border when not fullscreen. Values include:
      - "none": No border.
      - "single": A single line box.
      - "double": A double line box.
      - "rounded": Like "single", but with rounded corners.
      - "solid": Adds padding by a single whitespace cell.
      - "shadow": A drop shadow effect by blending with the background.
      - Or an array for a custom border. See `:h nvim_open_win` for details.
 - default is `single`.
#### maxWidth
 - An integer of how large in width the jfind can be as fullscreen until it becomes a popup window.
 - default is 120
#### maxHeight
 - An integer of how large in height the jfind can be as fullscreen until it becomes a popup window.
 - default is 28

lua jfind api
-------------
Work in progress.
