local FILE_PATH = debug.getinfo(1).source:sub(2)
local PLUGIN_DIR = vim.fn.fnamemodify(FILE_PATH, ':p:h:h:h')
local SCRIPTS_DIR = PLUGIN_DIR .. "/scripts"
local HOME = vim.fn.getenv("HOME")
local CACHE = vim.fn.getenv("XDG_CACHE_HOME")
if CACHE == "" or CACHE == vim.NIL then CACHE = HOME .. "/.cache" end

local JFIND_GITHUB_URL = "https://github.com/jake-stewart/jfind"
local JFIND_NVIM_GITHUB_URL = "https://github.com/jake-stewart/jfind.nvim"

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
    border = "single",
    exclude = {},

    -- deprecated
    formatPaths = false,
    key = nil,
}

local warnedAboutDeprecation = false;

local function ternary(cond, T, F)
    if cond then return T else return F end
end

local function jfindNvimPopup(script, command, flags, args, onComplete)
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

    -- some users may map escape to normal mode in a terminal buffer
    -- we want to ensure that config does not apply to the jfind window
    vim.api.nvim_buf_set_keymap(buf, "t", "<esc>", "<esc>", {noremap = true})

    local win = vim.api.nvim_open_win(buf, 1, opts)
    vim.api.nvim_win_set_option(win, "winhl", "normal:normal")

    local cmd = {PREPARE_JFIND_SCRIPT, script, command, flags}
    table.move(args, 1, #args, #cmd + 1, cmd)

    vim.fn.termopen(cmd, {on_exit = function(_, status, _)
        vim.api.nvim_win_close(win, 0)
        if status == 0 then
            onComplete()
        end
    end})
    vim.cmd.startinsert()
end

local function jfindTmuxPopup(script, command, flags, args, onComplete)
    local cmd = {
        TMUX_POPUP_SCRIPT,
        config.maxWidth,
        config.maxHeight,
        PREPARE_JFIND_SCRIPT,
        script,
        command,
        flags
    }
    table.move(args, 1, #args, #cmd + 1, cmd)
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
        flags = "--show-key --hints --select-both"
    else
        flags = "--show-key"
    end

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
        if (opts.callbackWrapper) then
            opts.callbackWrapper(callback, contents[2], contents[3])
        else
            callback(contents[2], contents[3])
        end
    end

    local args = ternary(opts.args, opts.args, {})
    local script = vim.fn.expand(opts.script)
    local command = ternary(opts.command, opts.command, "")

    if config.tmux and vim.fn.exists("$TMUX") == 1 then
        jfindTmuxPopup(script, command, flags, args, onComplete)
    else
        jfindNvimPopup(script, command, flags, args, onComplete)
    end
end

-- this function mimics the old behaviour of the plugin and works with old jfind
-- this function will get deleted after people transition
local function deprecatedJfind(opts)
    if vim.fn.executable("jfind") == 0 then
        print("jfind is not installed. " .. JFIND_GITHUB_URL)
        return
    end

    local flags
    if (opts.hints) then
        flags = "--hints --select-both"
    else
        flags = ""
    end

    local function onComplete()
        local success, contents = pcall(vim.fn.readfile, JFIND_OUT_PATH)
        if not success or #contents == 0 then
            return
        end
        opts.callback(contents[1], contents[2])
    end

    if config.tmux and vim.fn.exists("$TMUX") == 1 then
        jfindTmuxPopup(opts.script, flags, opts.args, onComplete)
    else
        jfindNvimPopup(opts.script, flags, opts.args, onComplete)
    end
end

local function findFile(opts)
    if opts == nil then opts = {} end
    if opts.callback == nil then opts.callback = vim.cmd.edit end
    if opts.hidden == nil then opts.hidden = true end
    local formatPaths = ternary(opts.formatPaths, "true", "false")
    local hidden = ternary(opts.hidden, "true", "false")
    jfind({
        script = JFIND_FILE_SCRIPT,
        args = {formatPaths, hidden},
        hints = opts.formatPaths,
        callback = opts.callback,
        callbackWrapper = function(callback, result, hint)
            callback(ternary(opts.formatPaths, hint, result))
        end
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
    if opts.callback == nil then opts.callback = editGotoLine end
    opts.exclude = opts.exclude or config.exclude or {}

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
    for _, v in pairs(opts.exclude) do
        table.insert(args, vim.fn.shellescape(flags.exclude .. v))
        if flags.excludeDir then
            table.insert(args, vim.fn.shellescape(flags.excludeDir .. v))
        end
    end

    jfind({
        command = command .. " " .. table.concat(args, " ") .. LIVE_GREP_FMT,
        hints = true,
        callback = opts.callback,
        callbackWrapper = function(callback, _, result)
            local idx = string.find(result, ":[0-9]*$", 0, false)
            local filename = string.sub(result, 1, idx - 1)
            local lineNumber = string.sub(result, idx + 1)
            callback(filename, lineNumber)
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

        -- deprecated
        if opts.key ~= nil then config.key = opts.key end
        if opts.formatPaths ~= nil then config.formatPaths = opts.formatPaths end
        --
    end

    vim.fn.writefile(config.exclude, JFIND_EXCLUDES_PATH)

    -- deprecated
    if (config.key ~= nil) then
        local keyMapped = vim.fn.maparg(config.key) ~= ""
        if not keyMapped then
            vim.keymap.set('n', config.key, function()
                deprecatedJfind({
                    script = JFIND_FILE_SCRIPT,
                    args = {ternary(config.formatPaths, "true", "false")},
                    hints = config.formatPaths,
                    callback = function(result, hint)
                        if config.formatPaths then
                            vim.cmd.edit(hint)
                        else
                            vim.cmd.edit(result)
                        end
                    end,
                })
                if not warnedAboutDeprecation then
                    local warning =
                        "jfind 1.0 has been released and your config is"
                        .. " deprecated. Visit " .. JFIND_NVIM_GITHUB_URL
                        .. " for new usage."
                    print(warning)
                    warnedAboutDeprecation = true
                end
            end)
        end
    end
    --

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
