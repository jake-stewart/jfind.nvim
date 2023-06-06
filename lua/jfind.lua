local filepath = debug.getinfo(1).source:sub(2)
local plugindir = vim.fn.fnamemodify(filepath, ':p:h:h')
local HOME = vim.fn.getenv("HOME")
local jfindGithubUrl = "https://github.com/jake-stewart/jfind"

local config = {
    maxWidth = 120,
    maxHeight = 28,
    border = "rounded"
}

local function editJfindPick()
    local ok, contents = pcall(vim.fn.readfile, HOME .. "/.cache/jfind_out")
    if ok and contents[1] then
        vim.cmd("edit " .. contents[1])
    end
end

local function onExit(window, status)
    vim.api.nvim_win_close(window, 0)
    if status == 0 then
        editJfindPick()
    end
end

local function setExclude(exclude)
    vim.fn.writefile(exclude, HOME .. "/.cache/jfind_excludes")
end

local function ternary(cond, T, F)
    if cond then return T else return F end
end

local function findFile()
    if not vim.fn.executable("jfind") then
        vim.cmd.echoerr("jfind is not installed. " .. jfindGithubUrl)
        return
    end

    local border = "none"
    local col = 0
    local row = 0

    local buf = vim.api.nvim_create_buf(false, true)
    local ui = vim.api.nvim_list_uis()[1]

    local width
    local height

    local vpad = ternary(vim.o.laststatus > 1, 2, 1)

    if vim.o.columns > config.max_width then
        width = ternary(
            vim.o.columns % 2, config.max_width - 1, config.max_width
        )
        if vim.o.lines > config.max_height then
            height = ternary(
                vim.o.lines % 2, config.max_height - 1, config.maxHeight
            )
            border = config.border
            col = (ui.width/2) - (width/2) - 1
            row = (ui.height/2) - (height/2) - 1
        else
            width = vim.o.columns
            height = vim.o.lines - vpad
        end
    else
        width = vim.o.columns
        height = vim.o.lines - vpad
    end

    local opts = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        anchor = "nw",
        style = "minimal",
        border = border
    }

    local win = vim.api.nvim_open_win(buf, 1, opts)
    vim.api.nvim_win_set_option(win, "winhl", "normal:normal")
    local t = vim.fn.termopen(plugindir .. "/scripts/jfind-file.sh",
                {on_exit = function(status, data) onExit(win, data) end})
    vim.cmd.startinsert()
end

local function findFileTmux()
    if not vim.fn.executable("jfind") then
        vim.cmd.echoerr("jfind is not installed. " .. jfindGithubUrl)
        return
    end
    vim.cmd("silent! !" .. plugindir .. "/scripts/tmux-jfind-file.sh "
        .. config.maxWidth .. " " .. config.maxHeight)
    editJfindPick()
end

local M = {
    setup = function(opts)
        if opts.exclude then
            setExclude(opts.exclude)
        end
        local mapopts = { noremap = true, silent = true }
        if opts.key then
            if opts.tmux then
                vim.keymap.set('n', opts.key, findFileTmux, mapopts)
            else
                vim.keymap.set('n', opts.key, findFile, mapopts)
            end
        end
        if opts.border then
            config.border = opts.border
        end
        if opts.maxWidth then
            config.maxWidth = opts.maxWidth
        end
        if opts.maxHeight then
            config.maxHeight = opts.maxHeight
        end
    end
}
return M
