# jfind.nvim

### Dependencies
 - [jfind](https://github.com/jake-stewart/jfind) (Required)
 - [fdfind](https://github.com/sharkdp/fd) (Recommended as a faster alternative to `find`)

### setup options
#### key
 - The key which will trigger the jfind window to open.
 - Default is `<c-f>`.
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
#### minWidth
 - An integer of how large in width the jfind can be as fullscreen until it becomes a popup window.
#### maxHeight
 - An integer of how large in height the jfind can be as fullscreen until it becomes a popup window.
#### formatPaths
 - A boolean of whether the paths should be formatted for better earching, or left as full paths.
 - default: `false`

### example [lazy](https://github.com/folke/lazy.nvim) config
```lua
require("lazy").setup({
    {
        "jake-stewart/jfind.nvim",
        keys = {
            {"<c-f>"},
        },
        config = function()
            require("jfind").setup({
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
                key = "<c-f>"
            });
        end
    },
    ...
```
