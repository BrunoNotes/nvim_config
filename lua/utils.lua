TERM_WIN = nil
local term_buf = nil

local M = {}

M.home = vim.fn.expand("~")
M.nvim_config = vim.fn.stdpath("config")
M.nvim_data = vim.fn.stdpath("data")

M.findBufferByName = function(name)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if string.find(buf_name, name) then
            -- return buf_name -- name
            return buf -- nuber
        end
    end
    return -1
end

M.tableSize = function(table)
    local size = 0
    for _ in pairs(table) do size = size + 1 end
    return size
end

M.getFileExt = function(path)
    local ext = path:match("%.([^%.]+)$")
    return ext and ext:lower() or ""
end

M.existsInTable = function(table, item)
    -- if table[item] == nil then
    --     return true
    -- end
    for _, value in ipairs(table) do
        if value:lower() == item:lower() then
            return true
        end
    end
    return false
end

M.openFileOrBuffer = function(file_path, buffer)
    if buffer == -1 then
        vim.cmd(string.format(":e %s", file_path))
    else
        vim.cmd(string.format(":buffer %s", buffer))
    end
end

M.fileExists = function(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

M.scanDir = function(self, directory, opts)
    -- Default options
    opts = opts or {}
    local ignore_patterns = opts.ignore_patterns or {
        "^%.+$",          -- Ignore hidden files/directories starting with .
        "^%.git$",        -- Ignore git directory
        "^node_modules$", -- Ignore node_modules
    }

    --- Check if path should be ignored
    ---@param path string Path to check
    ---@return boolean True if path should be ignored
    local function shouldIgnore(path)
        local filename = path:match("[^/]+$")
        for _, pattern in ipairs(ignore_patterns) do
            if filename:match(pattern) then
                return true
            end
        end
        return false
    end

    --- Recursive file scanning function
    ---@param dir string Directory to scan
    ---@return table List of file paths
    local function scanRecursive(dir)
        local files = {}

        -- Use vim.fn.readdir for directory listing
        local dir_contents = vim.fn.readdir(dir, function(name)
            return not shouldIgnore(name)
        end)

        for _, item in ipairs(dir_contents) do
            local full_path = dir .. '/' .. item

            -- Check if it's a directory
            if vim.fn.isdirectory(full_path) == 1 then
                -- Recursively scan subdirectories
                local subdir_files = scanRecursive(full_path)
                for _, subfile in ipairs(subdir_files) do
                    table.insert(files, subfile)
                end
            else
                -- Add file to list
                table.insert(files, full_path)
            end
        end

        return files
    end

    -- Normalize directory path and scan
    directory = vim.fn.fnamemodify(directory, ':p'):gsub('/$', '')
    return scanRecursive(directory)
end

M.readFile = function(self, path)
    local file = assert(io.open(path, "rb"))
    local content = file:read("*a")
    file:close()
    return content
end

M.writeFile = function(path, content)
    local file = assert(io.open(path, "w"))
    file:write(content)
    file:close()
end

M.readJson = function(self, path)
    local content = self:readFile(path)
    local json = vim.json.decode(content)
    return json
end

M.openFloatinWindow = function(self, buf)
    -- Create a floating window using the scratch buffer positioned in the middle
    local screen_size = 1.0
    local height = math.ceil(vim.o.lines * screen_size - 1)
    local width = math.ceil(vim.o.columns * screen_size)
    local win = vim.api.nvim_open_win(buf, true, {
        style = "minimal",
        relative = "editor",
        width = width,
        height = height,
        row = math.ceil((vim.o.lines - height) / 2),
        col = math.ceil((vim.o.columns - width) / 2),
        border = "none",
    })

    -- Change to the window that is floating to ensure termopen uses correct size
    vim.api.nvim_set_current_win(win)

    return win
end

M.openTerminal = function(self, opts)
    opts = opts or {}

    local floating = true
    if opts.floating ~= nil then
        floating = opts.floating
    end

    -- term_buf created on the top of the file
    local ok_buf, _ = pcall(vim.api.nvim_buf_get_name, term_buf)
    local ok_win, _ = pcall(vim.api.nvim_win_get_config, TERM_WIN)

    if floating then
        if not ok_win then
            term_buf = nil

            local run_result = self:runOnTerminal({
                cmd = vim.o.shell,
                buf = term_buf,
                delete_buffer = false,
            })

            TERM_WIN = run_result.win

            term_buf = vim.api.nvim_get_current_buf()
        else
            -- openFloatinWindow(term_buf)
            vim.api.nvim_win_set_config(TERM_WIN, {
                hide = false
            })
            vim.api.nvim_set_current_win(TERM_WIN)
        end
    else
        if ok_buf and term_buf ~= nil then
            vim.api.nvim_set_current_buf(term_buf)
        else
            vim.cmd.term()
            term_buf = vim.api.nvim_get_current_buf()
        end
    end

    -- Start in insert mode
    vim.cmd.startinsert()
end

M.closeFloatingWin = function()
    -- Check if the current buffer is in a floating window
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(win).relative ~= '' then
        -- defined in util
        if win == TERM_WIN then
            -- only hide if it is the terminall window
            vim.api.nvim_win_set_config(win, {
                hide = true
            })
            -- Get previous window
            local prev_win = vim.fn.win_getid(vim.fn.winnr('#'))

            -- Set previous window as current
            if prev_win and vim.api.nvim_win_is_valid(prev_win) then
                vim.api.nvim_set_current_win(prev_win)
            end
        else
            vim.cmd.close()
        end
    end
end

M.runOnTerminal = function(self, opts)
    local createBuffer = function(self, scratch)
        local buf = nil
        if not scratch then
            buf = vim.api.nvim_create_buf(true, false)
        else
            -- Create an immutable scratch buffer that is wiped once hidden
            buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
            vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
        end
        return buf
    end

    opts = opts or {}

    if opts ~= {} then
        if vim.fn.executable(opts.cmd) == 0 then
            print(opts .. " not found")
            return
        end
    end

    local delete_buffer = opts.delete_buffer or true
    local buf = opts.buf or createBuffer(delete_buffer)

    local win = self:openFloatinWindow(buf)

    -- Launch, and configure to close the window when the process exits
    local job_id = vim.fn.jobstart(opts.cmd, {
        -- detach = false,
        -- pty = true,
        term = true,
        on_exit = function(job, exit_code, event_type)
            if vim.api.nvim_win_is_valid(win) and not delete_buffer then
                vim.api.nvim_win_close(win, true)
            end
        end
    })

    vim.keymap.set("n", "<Esc>", function()
        self:closeFloatingWin()
    end, {
        buffer = true,
        desc = "Close floating window"
    })
    vim.keymap.set("n", "<leader>tv", function()
        self:splitFloatingWin("v")
    end, { buffer = true, desc = "Moves floating terminal to a split window" })
    vim.keymap.set("n", "<leader>ts", function()
        self:splitFloatingWin("s")
    end, { buffer = true, desc = "Moves floating terminal to a split window" })

    -- Start in insert mode
    vim.cmd.startinsert()

    return {
        job_id = job_id,
        win = win
    }
end

M.splitFloatingWin = function(self, opts)
    opts = opts or {}

    local split = opts.split or "s"
    split = split:lower()

    self:closeFloatingWin()

    if split == "v" then
        vim.cmd('vsplit')
    else
        vim.cmd('split')
    end

    self:openTerminal({ floating = false })
end

M.icons = {
    error = '',
    warn = '',
    hint = '',
    info = '',
    Constructor = "",
    Git = "",
    Circle = "",
    BoldArrowDown = "",
    BoldArrowLeft = "",
    BoldArrowRight = "",
    BoldArrowUp = "",
    Check = "✔",
    dots = {
        "⠋",
        "⠙",
        "⠹",
        "⠸",
        "⠼",
        "⠴",
        "⠦",
        "⠧",
        "⠇",
        "⠏",
    },
    moon = {
        "🌑 ",
        "🌒 ",
        "🌓 ",
        "🌔 ",
        "🌕 ",
        "🌖 ",
        "🌗 ",
        "🌘 ",
    }
}

return M
