local FILE_PATH = debug.getinfo(1).source:sub(2)
local PLUGIN_DIR = vim.fn.fnamemodify(FILE_PATH, ':p:h:h:h')
local SCRIPTS_DIR = PLUGIN_DIR .. "/scripts"
local HOME = vim.fn.getenv("HOME")
local CACHE = vim.fn.getenv("XDG_CACHE_HOME")
if CACHE == "" or CACHE == vim.NIL then CACHE = HOME .. "/.cache" end

local JFIND_GITHUB_URL = "https://github.com/jake-stewart/jfind"

local JFIND_OUT_PATH = CACHE .. "/jfind_out"
local JFIND_EXCLUDES_PATH = CACHE .. "/jfind_excludes"

local PREPARE_JFIND_SCRIPT = SCRIPTS_DIR .. "/prepare-jfind.sh"
local JFIND_TMUX_SCRIPT = SCRIPTS_DIR .. "/jfind-tmux.sh"
local JFIND_FILE_SCRIPT = SCRIPTS_DIR .. "/jfind-file.sh"
local JFIND_FORMATTED_FILE_SCRIPT = SCRIPTS_DIR .. "/jfind-formatted-file.sh"

local config = {
    maxWidth = 120,
    maxHeight = 28,
    key = "<c-f>",
    tmux = false,
    border = "single",
    formatPaths = false,
    exclude = {}
}

local function ternary(cond, T, F)
    if cond then return T else return F end
end

local function readJfindOut()
    local ok, contents = pcall(vim.fn.readfile, JFIND_OUT_PATH)
    if ok and #contents == 1 and #contents[1] > 0 then
        return contents[1]
    end
end

local function runJfindScriptNvim(script, onComplete)
    local border = "none"
    local col = 0
    local row = 0

    local buf = vim.api.nvim_create_buf(false, true)
    local ui = vim.api.nvim_list_uis()[1]

    local width
    local height

    local vpad = ternary(vim.o.laststatus > 1, 2, 1)

    if vim.o.columns > config.maxWidth then
        width = ternary(
            vim.o.columns % 2, config.maxWidth - 1, config.maxWidth
        )
        if vim.o.lines > config.maxHeight then
            height = ternary(
                vim.o.lines % 2, config.maxHeight - 1, config.maxHeight
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
    local cmd = {PREPARE_JFIND_SCRIPT, script}
    vim.fn.termopen(cmd, {on_exit = function(_, status, _)
        vim.api.nvim_win_close(win, 0)
        if status == 0 then
            onComplete()
        end
    end})
    vim.cmd.startinsert()
end

local function runJfindScriptTmux(script, onComplete)
    vim.fn.system({
        JFIND_TMUX_SCRIPT,
        "'" .. PREPARE_JFIND_SCRIPT .. "' '" .. script .. "'",
        config.maxWidth,
        config.maxHeight
    });
    onComplete()
end

function RunJfindScript(script, callback)
    if vim.fn.executable("jfind") == 0 then
        print("jfind is not installed. " .. JFIND_GITHUB_URL)
        return
    end

    local function onComplete()
        local result = readJfindOut()
        if result ~= nil then
            callback(result)
        end
    end

    if vim.fn.exists("$TMUX") == 1 and config.tmux then
        runJfindScriptTmux(script, onComplete)
    else
        runJfindScriptNvim(script, onComplete)
    end
end

return {
    setup = function(opts)
        if opts ~= nil then
            if opts.exclude ~= nil then config.exclude = opts.exclude end
            if opts.key ~= nil then config.key = opts.key end
            if opts.tmux ~= nil then config.tmux = opts.tmux end
            if opts.formatPaths ~= nil then
                config.formatPaths = opts.formatPaths end
            if opts.border ~= nil then config.border = opts.border end
            if opts.maxWidth ~= nil then config.maxWidth = opts.maxWidth end
            if opts.maxHeight ~= nil then config.maxHeight = opts.maxHeight end
        end
        vim.fn.writefile(config.exclude, JFIND_EXCLUDES_PATH)
        local mapopts = { noremap = true, silent = true }
        local script = ternary(config.formatPaths,
            JFIND_FORMATTED_FILE_SCRIPT, JFIND_FILE_SCRIPT)
        vim.keymap.set('n', config.key, function()
            RunJfindScript(script, vim.cmd.edit)
        end, mapopts)
    end
}
