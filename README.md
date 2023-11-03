jfind.nvim
==========
A plugin for using jfind as a neovim fuzzy finder. Works for macos, linux, and windows via WSL.

<img width="834" alt="Screenshot 2023-06-29 at 10 09 51 pm" src="https://github.com/jake-stewart/jfind.nvim/assets/83528263/7bf9d420-b596-4273-9d4b-95ac8dbc9752">

Dependencies
------------
 - [jfind](https://github.com/jake-stewart/jfind) (Required)
 - [fdfind](https://github.com/sharkdp/fd) (Recommended as a faster alternative to `find`)
 - [ripgrep](https://github.com/BurntSushi/ripgrep) (Recommended as a faster alternative to `grep`)
 - [bat](https://github.com/sharkdp/bat) (Recommended as a syntax highlighted alternative to `cat`)

You can install jfind with this one liner. You will need git, cmake, and make.
```
git clone https://github.com/jake-stewart/jfind && cd jfind && cmake -S . -B build && cd build && sudo make install
```

**If you are migrating to 2.0 from an earlier version, make sure to recompile jfind!**

Installation
------------

#### [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{ "jake-stewart/jfind.nvim", branch = "2.0" }
```

#### [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug "jake-stewart/jfind.nvim", { "branch": "2.0" }
```

#### [dein.vim](https://github.com/Shougo/dein.vim)
```vim
call dein#add("jake-stewart/jfind.nvim", { "rev": "2.0" })
```

#### [packer.nvim](wbthomason/packer.nvim)
```lua
use { "jake-stewart/jfind.nvim", branch = "2.0" }
```


Example Config
--------------

```lua
local jfind = require("jfind")
local key = require("jfind.key")

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
    windowBorder = true,
    tmux = true,
});

-- fuzzy file search can be started simply with
vim.keymap.set("n", "<c-f>", jfind.findFile)

-- or you can provide more customization
-- for more information, read the "Lua Jfind Interface" section
vim.keymap.set("n", "<c-f>", function()
    jfind.findFile({
        formatPaths = true,
        hidden = true,
        queryPosition = "top",
        preview = true,
        previewPosition = "right",
        callback = {
            [key.DEFAULT] = vim.cmd.edit,
            [key.CTRL_S] = vim.cmd.split,
            [key.CTRL_V] = vim.cmd.vsplit,
        }
    })
end)

-- make sure to rebuld jfind if you want live grep
vim.keymap.set("n", "<leader><c-f>", function()
    jfind.liveGrep({
        exclude = {"*.hpp"},       -- overrides setup excludes
        hidden = true,             -- grep hidden files/directories
        caseSensitivity = "smart", -- sensitive, insensitive, smart
                                   --     will use vim settings by default
        preview = true,
        previewPosition = "top",
        callback = {
            [key.DEFAULT] = jfind.editGotoLine,
            [key.CTRL_B] = jfind.splitGotoLine,
            [key.CTRL_N] = jfind.vsplitGotoLine,
        }
    })
end)

```

### Setup Options
|Option|Description
|-|-|
|`tmux`|a boolean of whether a tmux window is preferred over a neovim window. If tmux is not active, then this value is ignored. Default is `false`.|
|`exclude`|a list of strings of files/directories that should be ignored. Entries can contain wildcard matching (e.g. `*.png`). Default is an empty list.|
|`maxWidth`|An integer of how large in width the jfind can be as fullscreen until it becomes a popup window. default is `120`.|
|`maxHeight`|An integer of how large in height the jfind can be as fullscreen until it becomes a popup window. default is `28`.|
|`windowBorder`|A boolean of whether jfind should be surrounded with a border. Default is `true`.|


Lua Jfind Interface
-------------------
This section is useful if you want to create your own fuzzy finders using
jfind, or if you want to understand the configuration better.

### The jfind function
This plugin provides the `jfind()` function, which can be accessed via
`require("jfind").jfind`. This function opens a tmux or nvim popup based on
user configuration, performs fuzzy finding, and calls a provided callback with
the result if there is one.

### Fuzzy finding script output
Below is an example usage of `jfind()`. It takes a script, which in this case
is the `seq` command. It also provides an argument to the `seq` command.
Upon completion, the result of the fuzzy finding will be printed using the
provided `print` callback. The `seq` command could just as easily have been a
path to a shell script, as is the case for `findFile()`.

```lua
local jfind = require("jfind")

jfind.jfind({
    script = "seq",
    args = {100},
    callback = print
})
```

### Fuzzy finding a list of strings
Instead of a program/script, you can provide a list of strings with the input
option. This is useful for generating the input data in lua instead of a shell
script, since a shell script does not have access to neovim state.

```lua
local jfind = require("jfind")

jfind.jfind({
    input = {"one", "two", "three", "four"},
    callback = print
})
```

### Multiple keybindings
The callback option is either a function or a table. You can provide a table
if you want different actions for different keybinds. For example, you may want
to vertically split when pressing `<c-v>` on an item. Below is an example of
having multiple keybindings.

```lua
local jfind = require("jfind")
local key = require("jfind.key")

jfind.jfind({
    script = "ls",
    callback = {
        [key.DEFAULT] = vim.cmd.edit,
        [key.CTRL_V] = vim.cmd.vsplit,
        [key.CTRL_S] = vim.cmd.split
    }
})
```

the `key.DEFAULT` applies to the user hitting enter or double clicking on an
item, unless overridden.

### Hints
You may have noticed that the builtin `findFile()` accepts an option called
`formatPaths`. When this option is true, the jfind window has two columns,
where the one on the right shows the full path, but is not searchable. These
are called hints. They are useful for separating what the user is searching for
from the result we want.

For instance, when I am searching for a path, I do not want to search the full
`~/projects/foo/bar/baz/item/item.java`, I just want to search the final
`item/item.java`. In this case, the `item/item.java` would be the search item,
and `~/projects/foo/bar/baz/item/item.java` would be the hint. We can then use
the hint when actually editing the file, since trying to edit `item/item.java`
is missing its hierarchy.

```lua
local jfind = require("jfind")

jfind.jfind({
    input = {"item one", "hint one", "item two", "hint two"},
    hints = true,
    callback = function(result)
        print("result: " .. result)
    end
})
```

### Preview
You can run a command on the selected item and use the output as a preview for that item.
You will need "figlet" to run the following example:

```lua
local jfind = require("jfind")

jfind.jfind({
    input = {1, 2, 3, 4, 5},
    preview = "figlet",
    previewPosition = "right",
    callback = function(result)
        print("result: " .. result)
    end
})
```

### Wrapping the callbacks
Sometimes it may be useful to wrap each callback in a function. This can save
needing the same boilerplate for every callback.

```lua
local jfind = require("jfind")
local key = require("jfind.key")

jfind.jfind({
    input = get_buffers(),
    hints = true,
    callbackWrapper = function(callback, path)
        -- do something to path, and then call the provided callback
        callback(path)
    end,
    callback = {
        [key.DEFAULT] = vim.cmd.edit,
        [key.CTRL_S] = vim.cmd.split,
        [key.CTRL_V] = vim.cmd.vsplit,
    }
})

```


### Example: Fuzzy finding open buffers
This example combines it all together to create a fuzzy finder for open
buffers.

```lua
local jfind = require("jfind")
local key = require("jfind.key")

local function get_buffers()
    local buffers = {}
    for i, buf_hndl in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf_hndl) then
            local path = vim.api.nvim_buf_get_name(buf_hndl)
            if path ~= nil and path ~= "" then
                buffers[i * 2 - 1] = jfind.formatPath(path)
                buffers[i * 2] = path
            end
        end
    end
    return buffers
end

jfind.jfind({
    input = get_buffers(),
    hints = true,
    callback = {
        [key.DEFAULT] = vim.cmd.edit,
        [key.CTRL_S] = vim.cmd.split,
        [key.CTRL_V] = vim.cmd.vsplit,
    }
})
```

### Using external programs to filter results

`liveGrep()` uses grep and ripgrep for the matching process.
Every time you type a key in jfind, a new process is spawned and fed the current query.
You can do the same thing with the `command` option in `jfind.jfind()`.

A good example to play with would be the following:

```
jfind.jfind({
    command = "seq {}",
    callback = print
})
```
