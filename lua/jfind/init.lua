local FILE_PATH = debug.getinfo(1).source:sub(2)
local PLUGIN_DIR = vim.fn.fnamemodify(FILE_PATH, ':p:h:h:h')
local SCRIPTS_DIR = PLUGIN_DIR .. "/scripts"
local HOME = vim.fn.getenv("HOME")
local CACHE = vim.fn.getenv("XDG_CACHE_HOME")
if CACHE == "" or CACHE == vim.NIL then CACHE = HOME .. "/.cache" end

local JFIND_GITHUB_URL = "https://github.com/jake-stewart/jfind"

local JFIND_INPUT_PATH = CACHE .. "/jfind_in"
local JFIND_OUT_PATH = CACHE .. "/jfind_out"
local JFIND_EXCLUDES_PATH = CACHE .. "/jfind_excludes"

local PREPARE_JFIND_SCRIPT = SCRIPTS_DIR .. "/prepare-jfind.sh"
local TMUX_POPUP_SCRIPT = SCRIPTS_DIR .. "/tmux-popup.sh"
local JFIND_FILE_SCRIPT = SCRIPTS_DIR .. "/jfind-file.sh"

local LIVE_GREP_COMMANDS = {
    rg = {
        fixed = "-F",
        null = "--null",
        numbers = "-n",
        caseSensitivity = {
            smart = "-S",
            insensitive = "-i",
            sensitive = "",
        },
        showHidden = "--hidden",
        exclude = "--iglob=!",
        include = "--iglob=",
    },
    grep = {
        fixed = "-F",
        null = "--null",
        numbers = "-n",
        caseSensitivity = {
            smart = "-S",
            insensitive = "-i",
            sensitive = "",
        },
        hideHidden = "*/.*",
        exclude = "--exclude=",
        excludeDir = "--excludeDir=",
        include = "--include=",
        includeDir = "--includeDir=",
    }
}

local LIVE_GREP_FMT = [[ {} | xargs -0 -n 1 | awk -F: '
    NR % 2 == 1 {
        previous = $0
    }
    NR % 2 == 0 {
        print substr($0, index($0, $2))
        print previous FS $1
        fflush(stdout)
    }
']]

local config = {
    maxWidth = 120,
    maxHeight = 28,
    tmux = false,
    windowBorder = true,
    exclude = {},
}

local function ternary(cond, T, F)
    if cond then return T else return F end
end

local function jfindNvimPopup(script, command, query, preview, previewLine, history, flags, args, onComplete)
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
        border = "none"
    }

    -- override user bindings
    vim.api.nvim_buf_set_keymap(buf, "t", "<esc>", "<esc>", {noremap = true})
    vim.api.nvim_buf_set_keymap(buf, "t", "<c-j>", "<c-j>", {noremap = true})
    vim.api.nvim_buf_set_keymap(buf, "t", "<c-k>", "<c-k>", {noremap = true})
    vim.api.nvim_buf_set_keymap(buf, "t", "<c-u>", "<c-u>", {noremap = true})
    vim.api.nvim_buf_set_keymap(buf, "t", "<bs>", "<bs>", {noremap = true})
    vim.api.nvim_buf_set_keymap(buf, "t", "<cr>", "<cr>", {noremap = true})

    local win = vim.api.nvim_open_win(buf, true, opts)
    vim.api.nvim_win_set_option(win, "winhl", "normal:normal")

    local cmd = {
        PREPARE_JFIND_SCRIPT, script, command, query,
        preview, previewLine, history, flags
    }
    for i = 1, #args do
        table.insert(cmd, args[i])
    end

    vim.fn.termopen(cmd, {on_exit = function(_, status, _)
        vim.api.nvim_win_close(win, false)
        if status == 0 then
            onComplete()
        end
    end})
    vim.cmd.startinsert()
end

local function jfindTmuxPopup(script, command, query, preview, previewLine, history, flags, args, onComplete)
    local cmd = {
        TMUX_POPUP_SCRIPT,
        config.maxWidth,
        config.maxHeight,
        PREPARE_JFIND_SCRIPT,
        script,
        command,
        query,
        preview,
        previewLine,
        history,
        flags
    }
    for i = 1, #args do
        table.insert(cmd, args[i])
    end

    vim.fn.system(cmd);
    if vim.v.shell_error == 0 then
        onComplete()
    end
end

local function jfind(opts)
    if (opts.input ~= nil) then
        vim.fn.writefile(opts.input, JFIND_INPUT_PATH)
        opts.args = {JFIND_INPUT_PATH}
        opts.script = "cat"
    end

    if vim.fn.executable("jfind") == 0 then
        print("jfind is not installed. " .. JFIND_GITHUB_URL)
        return
    end

    if (opts.callback == nil) then
        print("No callback provided")
        return
    end

    local flags
    if (opts.hints) then
        flags = "--show-key --hints --select-hint"
    else
        flags = "--show-key"
    end
    if (opts.selectAll) then
        flags = flags .. " --select-all"
    end
    if config.windowBorder then
        flags = flags .. " --external-border"
    end
    if opts.previewMinWidth then
        flags = flags .. " --preview-min-width=" .. opts.previewMinWidth
    end
    if opts.previewPercent then
        flags = flags .. " --preview-percent=" .. opts.previewPercent
    end
    if opts.previewPosition then
        flags = flags .. " --preview-position=" .. opts.previewPosition
    end
    if opts.queryPosition then
        flags = flags .. " --query-position=" .. opts.queryPosition
    end

    if not opts.previewLine then opts.previewLine = "" end
    if opts.preview == nil then opts.preview = "" end

    if type(opts.callback) == "table" then
        local keys = ""
        for k, _ in pairs(opts.callback) do
            keys = keys .. k .. ","
        end
        flags = flags .. " --additional-keys=" .. keys
    else
        opts.callback = {
            [0] = opts.callback
        }
    end

    local function onComplete()
        local success, contents = pcall(vim.fn.readfile, JFIND_OUT_PATH)
        if not success or #contents == 0 then
            return
        end
        local callback = opts.callback[tonumber(contents[1])]
        if (callback == nil) then
            callback = opts.callback[0]
        end
        if (callback == nil) then
            return
        end
        local result;
        if (opts.selectAll) then
            result = {unpack(contents, 2, #contents)}
        else
            result = contents[2]
        end
        if (opts.callbackWrapper) then
            opts.callbackWrapper(callback, result)
        else
            callback(result)
        end
    end

    local args = ternary(opts.args, opts.args, {})
    local script = vim.fn.expand(opts.script)
    local command = ternary(opts.command, opts.command, "")
    local query = ternary(opts.query, opts.query, "")
    local history = ternary(opts.history, opts.history, "")

    if config.tmux and vim.fn.exists("$TMUX") == 1 then
        jfindTmuxPopup(script, command, query, opts.preview, opts.previewLine, history, flags, args, onComplete)
    else
        jfindNvimPopup(script, command, query, opts.preview, opts.previewLine, history, flags, args, onComplete)
    end
end

local function findFile(opts)
    if opts == nil then opts = {} end
    if opts.callback == nil then
        opts.callback = opts.selectAll
            and function(_) end
            or vim.cmd.edit
    end
    if opts.hidden == nil then opts.hidden = true end
    if opts.history == nil then opts.history = "~/.cache/jfind_find_file_history" end
    if opts.history == false then opts.history = nil end
    if type(opts.findFlags) ~= "table" then opts.findFlags = {} end
    local formatPaths = ternary(opts.formatPaths, "true", "false")
    local hidden = ternary(opts.hidden, "true", "false")

    local preview = nil
    if opts.preview == true then
        preview = ternary(
            vim.fn.executable("bat") == 1,
            "bat --color always --theme ansi --style plain",
            "cat"
        )
    elseif opts.preview then
        preview = opts.preview
    end

    local args = {formatPaths, hidden}
    if (opts.findFlags ~= nil) then
        table.insert(args, table.concat(opts.findFlags, " "))
    end

    jfind({
        script = JFIND_FILE_SCRIPT,
        args = args,
        hints = opts.formatPaths,
        selectAll = opts.selectAll,
        preview = preview,
        query = opts.query,
        previewPosition = opts.previewPosition,
        previewPercent = opts.previewPercent,
        previewMinWidth = opts.previewMinWidth,
        queryPosition = opts.queryPosition,
        history = opts.history,
        callback = opts.callback,
        flags = opts.findFlags
    })
end

local function editGotoLine(file, line)
    vim.cmd("edit +" .. line .. " " .. file)
end

local function splitGotoLine(file, line)
    vim.cmd("split +" .. line .. " " .. file)
end

local function vsplitGotoLine(file, line)
    vim.cmd("vsplit +" .. line .. " " .. file)
end

local function getDefaultCaseSensitivity()
    if vim.o.ignorecase then
        if vim.o.smartcase then
            return "smart"
        end
        return "insensitive"
    end
    return "sensitive"
end

local function liveGrep(opts)
    if opts == nil then opts = {} end
    if opts.hidden == nil then opts.hidden = true end
    if opts.fixed == nil then opts.fixed = false end
    if opts.caseSensitivity == nil then
        opts.caseSensitivity = getDefaultCaseSensitivity();
    end
    if opts.history == nil then opts.history = "~/.cache/jfind_live_grep_history" end
    if opts.history == false then opts.history = nil end
    opts.callback = opts.selectAll
        and function(_) end
        or vim.cmd.edit
    opts.exclude = opts.exclude or config.exclude or {}
    opts.include = opts.include or {}
    if opts.preview == nil then opts.preview = true end

    local preview = nil
    if opts.preview == true then
        preview = ternary(
            vim.fn.executable("bat") == 1,
            "bat --color always --theme ansi --style plain",
            "cat"
        )
    elseif opts.preview then
        preview = opts.preview
    end

    if preview then
        preview = preview .. " $(echo {} | awk -F: '{print $1}')"
    end

    local command = ternary(vim.fn.executable("rg") == 1, "rg", "grep")
    local flags = LIVE_GREP_COMMANDS[command]
    local args = {flags.numbers, flags.null}
    if opts.fixed then table.insert(args, flags.fixed) end
    table.insert(args, flags.caseSensitivity[opts.caseSensitivity])
    if opts.hidden then
        if flags.showHidden then table.insert(args, flags.showHidden) end
    else
        if flags.hideHidden then table.insert(args, flags.hideHidden) end
    end
    for _, v in pairs(opts.include) do
        table.insert(args, vim.fn.shellescape(flags.include .. v))
        if flags.includeDir then
            table.insert(args, vim.fn.shellescape(flags.includeDir .. v))
        end
    end
    for _, v in pairs(opts.exclude) do
        table.insert(args, vim.fn.shellescape(flags.exclude .. v))
        if flags.excludeDir then
            table.insert(args, vim.fn.shellescape(flags.excludeDir .. v))
        end
    end
    if command == "rg" then
        if opts.rgFlags then
            for i = 1, #opts.rgFlags do
                table.insert(args, opts.rgFlags[i])
            end
        end
    elseif opts.grepFlags then
        for i = 1, #opts.grepFlags do
            table.insert(args, opts.grepFlags[i])
        end
    end

    table.insert(args, "--")

    jfind({
        command = command .. " " .. table.concat(args, " ") .. LIVE_GREP_FMT,
        hints = true,
        previewLine = "\\d*$",
        preview = preview,
        query = opts.query,
        callback = opts.callback,
        selectAll = opts.selectAll,
        previewPosition = opts.previewPosition,
        previewPercent = opts.previewPercent,
        previewMinWidth = opts.previewMinWidth,
        history = opts.history,
        queryPosition = opts.queryPosition,
        callbackWrapper = function(callback, result)
            if (opts.selectAll) then
                local results = {}
                for i, v in pairs(result) do
                    local idx = string.find(v, ":[0-9]*$", 0, false)
                    local filename = string.sub(v, 1, idx - 1)
                    local lineNumber = string.sub(v, idx + 1)
                    results[i] = {filename, lineNumber}
                end
                callback(results)
            else
                local idx = string.find(result, ":[0-9]*$", 0, false)
                local filename = string.sub(result, 1, idx - 1)
                local lineNumber = string.sub(result, idx + 1)
                callback(filename, lineNumber)
            end
        end
    })
end

local function formatPath(path)
    local parts = {}
    for part in string.gmatch(path, "[^/]+") do
        table.insert(parts, part)
    end
    local total = #parts
    if total == 1 then
        return path
    elseif total == 2 then
        return parts[1] .. "/" .. parts[2]
    else
        return parts[total - 1] .. "/" .. parts[total]
    end
end

local function setup(opts)
    if opts ~= nil then
        if opts.exclude ~= nil then config.exclude = opts.exclude end
        if opts.tmux ~= nil then config.tmux = opts.tmux end
        if opts.border ~= nil then config.border = opts.border end
        if opts.maxWidth ~= nil then config.maxWidth = opts.maxWidth end
        if opts.maxHeight ~= nil then config.maxHeight = opts.maxHeight end
    end

    vim.fn.writefile(config.exclude, JFIND_EXCLUDES_PATH)

end

return {
    setup = setup,
    findFile = findFile,
    liveGrep = liveGrep,
    jfind = jfind,

    -- util functions
    formatPath = formatPath,
    editGotoLine = editGotoLine,
    splitGotoLine = splitGotoLine,
    vsplitGotoLine = vsplitGotoLine,
}
