local log = {}

local M = {}

M.home = vim.fn.expand("~")
M.nvim_config = vim.fn.stdpath("config")
M.nvim_data = vim.fn.stdpath("data")

M.TERM_WIN = nil
M.term_buf = nil
M.buf_before_term = nil
M.last_term_cmd = nil
M.os_name = vim.uv.os_uname().sysname

if M.os_name == "Windows_NT" then
    M.path_char = "\\"
else
    M.path_char = "/"
end

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
        local filename = path:match("[^" .. self.path_char .. "]+$")
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
            local full_path = dir .. self.path_char .. item

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
    directory = vim.fn.fnamemodify(directory, ':p'):gsub(self.path_char .. '$', '')
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
    self.buf_before_term = vim.api.nvim_get_current_buf()

    opts = opts or {}

    local floating = true
    if opts.floating ~= nil then
        floating = opts.floating
    end

    -- term_buf created on the top of the file
    local ok_buf, _ = pcall(vim.api.nvim_buf_get_name, self.term_buf)
    local ok_win, _ = pcall(vim.api.nvim_win_get_config, self.TERM_WIN)

    if floating then
        if not ok_win then
            self.term_buf = nil

            local run_result = self:runOnTerminal({
                cmd = vim.o.shell,
                buf = self.term_buf,
                delete_buffer = false,
            })

            if run_result ~= nil then
                self.TERM_WIN = run_result.win

                self.term_buf = vim.api.nvim_get_current_buf()
            end
        else
            -- openFloatinWindow(self.term_buf)
            vim.api.nvim_win_set_config(self.TERM_WIN, {
                hide = false
            })
            vim.api.nvim_set_current_win(self.TERM_WIN)
        end
    else
        if ok_buf and self.term_buf ~= nil then
            vim.api.nvim_set_current_buf(self.term_buf)
        else
            vim.cmd.term()
            self.term_buf = vim.api.nvim_get_current_buf()
        end

        vim.keymap.set("n", "<Esc>", function()
            vim.api.nvim_set_current_buf(self.buf_before_term)
        end, {
            buffer = true,
            desc = "Switch terminal window"
        })
    end

    -- Start in insert mode
    vim.cmd.startinsert()
end


M.sendCmdToTerminal = function(self, cmd)
    local current_buffer = vim.api.nvim_get_current_buf()
    local current_cmd = ""

    if cmd ~= nil then
        current_cmd = cmd
    else
        if self.last_term_cmd ~= nil then
            current_cmd = self.last_term_cmd
        else
            local in_cmd = vim.fn.input("Command: ")
            current_cmd = in_cmd
        end
    end

    if current_buffer ~= self.term_buf then
        self:openTerminal({ floating = false })
    end

    local chan = vim.b[self.term_buf].terminal_job_id

    if chan then
        vim.api.nvim_chan_send(chan, current_cmd .. "\r")
        self.last_term_cmd = current_cmd
        return
    end
end

M.closeFloatingWin = function(self)
    -- Check if the current buffer is in a floating window
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(win).relative ~= '' then
        -- defined in util
        if win == self.TERM_WIN then
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

M.createBuffer = function(self, scratch)
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


M.runOnTerminal = function(self, opts)
    opts = opts or {}

    if opts ~= {} then
        if vim.fn.executable(opts.cmd) == 0 then
            print(opts .. " not found")
            return
        end
    end

    local delete_buffer = opts.delete_buffer or true
    local buf = opts.buf or self:createBuffer(delete_buffer)

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
    Gear = "",
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

M.log = function(message) table.insert(log, message) end

M.printLog = function()
    print(vim.inspect(log))
end

M.stringEndsWith = function(str, ending)
    return ending == "" or str:sub(- #ending) == ending
end

M.stringStartsWith = function(str, start)
    return str:sub(1, start:len()) == start
end

return M
