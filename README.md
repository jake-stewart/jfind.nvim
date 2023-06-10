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

Installation
------------

#### [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{ "jake-stewart/jfind.nvim", branch = "1.0" }
```

#### [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug "jake-stewart/jfind.nvim", { "branch": "1.0" }
```

#### [dein.vim](https://github.com/Shougo/dein.vim)
```vim
call dein#add("jake-stewart/jfind.nvim", { "rev": "1.0" })
```

#### [packer.nvim](wbthomason/packer.nvim)
```lua
use {
  "jake-stewart/jfind.nvim", branch = "1.0"
}
```


Example Config
--------------

```lua
local jfind = require("jfind")
local Key = require("jfind.key")

jfind.setup({
    exclude = {
        ".git",
        ".idea",
        ".vscode",
        ".sass-cache",
        ".class",
        "__pycache__",
        "node_modules",
        "target",
        "build",
        "tmp",
        "assets",
        "dist",
        "public",
        "*.iml",
        "*.meta"
    },
    border = "rounded",
    tmux = true,
});

-- fuzzy file search can be started simply with
-- (this is currently broken i am fixing it)
vim.keymap.set("n", "<c-f>", jfind.findFile)

-- or you can provide more customization
vim.keymap.set("n", "<c-f>", function()
    jfind.findFile({
        formatPaths = true,
        callback = {
            [Key.DEFAULT] = vim.cmd.edit,
            [Key.CTRL_S] = vim.cmd.split,
            [Key.CTRL_V] = vim.cmd.vsplit,
        }
    })
end)
```

### Setup Options
|Option|Description
|-|-|
|`tmux`|a boolean of whether a tmux window is preferred over a neovim window. If tmux is not active, then this value is ignored. Default is `false`.|
|`exclude`|a list of strings of files/directories that should be ignored. Entries can contain wildcard matching (e.g. `*.png`). Default is an empty list.|
|`border`|The style of the border when not fullscreen. The default is `"single"`. Possible values include: <br>- `"none"`: No border.<br>- `"single"`: A single line box.<br>- `"double"`: A double line box.<br>- `"rounded"`: Like "single", but with rounded corners.<br>- `"solid"`: Adds padding by a single whitespace cell.<br>- `"shadow"`: A drop shadow effect by blending with the background.<br>- Or an array for a custom border. See `:h nvim_open_win` for details.|
|`maxWidth`|An integer of how large in width the jfind can be as fullscreen until it becomes a popup window. default is `120`.|
|`maxHeight`|An integer of how large in height the jfind can be as fullscreen until it becomes a popup window. default is `28`.|

Lua Jfind Interface
-------------------
Work in progress.
