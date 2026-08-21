local utils = require("utils");
local icons = utils.icons;

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
    desc = "Format options",
    group = vim.api.nvim_create_augroup("b_format_options", { clear = true }),
    callback = function()
        -- vim.cmd("set formatoptions-=cro")
        vim.opt_local.formatoptions:remove({ "c", "r", "o" })
    end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("b_highlight_yank", { clear = true }),
    callback = function()
        vim.hl.on_yank({ timeout = 50 })
    end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    desc = "Remove white space at the end",
    group = vim.api.nvim_create_augroup("b_remove_whitespace", { clear = true }),
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

vim.api.nvim_create_autocmd({ "VimEnter" }, {
    desc = "Change CWD on enter",
    group = vim.api.nvim_create_augroup("b_change_cwd", { clear = true }),
    callback = function()
        local file_cwd = vim.fn.expand("%:p:h")
        if (file_cwd ~= nil or file_cwd ~= "") then
            local path_to_change = file_cwd
            if string.sub(file_cwd, 1, 3) == "oil" then
                path_to_change = string.sub(file_cwd, 7, string.len(file_cwd))
            end

            local ok, _ = pcall(vim.fn.chdir, path_to_change)

            if ok then
                print(string.format("CWD changed to: %s", vim.loop.cwd()))
            end
        end
    end,
})

vim.api.nvim_create_autocmd({ "VimEnter" }, {
    desc = "Clear jump list on enter",
    group = vim.api.nvim_create_augroup("b_jump_list", { clear = true }),
    callback = function()
        vim.cmd.cle();
    end,
})

vim.api.nvim_create_autocmd({ "VimLeave" }, {
    desc = "Clear jump list on exit",
    group = vim.api.nvim_create_augroup("b_jump_list", { clear = true }),
    callback = function()
        vim.cmd.cle();
    end,
})

vim.api.nvim_create_autocmd({ "TermEnter" }, {
    desc = "Terminal local options",
    group = vim.api.nvim_create_augroup("b_custom_term_open", {}),
    callback = function(buf)
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.scrolloff = 0
    end,
})

vim.api.nvim_create_autocmd({ "TermLeave" }, {
    desc = "Terminal local options",
    group = vim.api.nvim_create_augroup("b_custom_term_close", {}),
    callback = function(buf)
        local win_config = vim.api.nvim_win_get_config(0)
        if win_config.relative ~= "" then
            -- floating
        else
            local current_buf = vim.api.nvim_get_current_buf()
            -- non floating
            if utils.term_buf == current_buf then
                vim.opt_local.number = true
                vim.opt_local.relativenumber = true
                vim.opt_local.scrolloff = 10
            end
        end
    end,
})

local statusBar = function()
    local buf_id = vim.api.nvim_get_current_buf()

    local getFileName = function()
        local file_path = vim.api.nvim_buf_get_name(buf_id)

        file_path = string.gsub(file_path, vim.loop.cwd() .. utils.path_char, "")

        return file_path
    end

    local getGitStatus = function()
        -- check if git exists
        if vim.fn.executable("git") == 1 then
            local is_git_repo = vim.fn.system { "git", "rev-parse", "--is-inside-work-tree" }:gsub("\n[^\n]*(\n?)$",
                "%1")
            if (is_git_repo == "true") then
                local git_branch = vim.fn.system { "git", "branch", "--show-current" }:gsub("\n[^\n]*(\n?)$", "%1")
                return string.format('%s %s', icons.Git, git_branch)
            else
                return ""
            end
        else
            return ""
        end
    end

    local getLspName = function()
        local lsp_clients = vim.lsp.get_clients({ bufnr = buf_id })

        if lsp_clients ~= nil then
            local lsp_names = ""
            for _, value in ipairs(lsp_clients) do
                if lsp_names == "" then
                    lsp_names = tostring(value.name)
                else
                    lsp_names = lsp_names .. ", " .. tostring(value.name)
                end
            end

            if lsp_names ~= "" then
                -- return string.format('LSP: %s', lsp_names)
                return string.format('%s %s', icons.Gear, lsp_names)
            else
                return ""
            end
        end
    end

    vim.opt.statusline = table.concat({
        -- left
        " ",
        getFileName(),
        "%=",
        -- middle
        "%=",
        -- right
        getLspName(),
        " ",
        getGitStatus(),
        " ",
        '%l:%c',
        " ",
    })
end

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "LspAttach" }, {
    desc = "Status line",
    group = vim.api.nvim_create_augroup("b_status_line", { clear = true }),
    callback = statusBar,
})

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("b_custom_qf_autoclose", { clear = true }),
    pattern = "qf",
    callback = function()
        vim.keymap.set("n", "<CR>", function()
            local qf_line = vim.fn.line(".")

            vim.cmd.cclose()

            ---@diagnostic disable-next-line: param-type-mismatch
            local ok, _ = pcall(vim.cmd, qf_line .. "cc")
            if not ok then
                vim.notify("Could not jump to quickfix item", vim.log.levels.WARN)
            end
        end, { buffer = true, silent = true, desc = "Select item and auto-close quickfix" })
    end,
})

-- formats the quickfix list
function _G.qfFormat(info)
    local items = vim.fn.getqflist({ id = info.id, items = 1 }).items
    local list = {}
    -- utils.log(items)

    if items == nil then
        return list
    end

    for idx, item in ipairs(items) do
        if item then
            if item.bufnr == 0 and (item.text == "" or item.text == nil) then
                table.insert(list, item.raw or "")
            else
                local file_name = item.bufnr > 0 and vim.fn.bufname(item.bufnr) or ""
                if file_name ~= "" then
                    file_name = vim.fn.fnamemodify(file_name, ":~:.") -- Shorten path
                end

                local line_num = item.lnum > 0 and tostring(item.lnum) or ""
                local col = item.col > 0 and tostring(item.col) or ""
                local pos = line_num ~= "" and (col ~= "" and string.format("%s:%s", line_num, col) or line_num) or ""

                local text = item.text or ""

                local str = string.format("%-30s │ %-8s │ %s", file_name, pos, text)
                table.insert(list, str)
            end
        end
    end

    return list
end

-- Set Neovim to use our custom formatter globally
vim.o.quickfixtextfunc = "v:lua.qfFormat"

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("b_custom_qf_highlight", { clear = true }),
    pattern = "qf",
    callback = function()
        -- Clear standard layout quirks
        vim.wo.wrap = false

        vim.fn.matchadd("Comment", [[\v│]]) -- divider

        -- vim.fn.matchadd("DiagnosticError", [[\v[Ee]rror\ze:]])
        -- vim.fn.matchadd("DiagnosticWarn", [[\v[Ww]arning\ze:]])
        -- vim.fn.matchadd("Comment", [[\v[Nn]ote\ze:]])

        vim.fn.matchadd("Title", [[\v^[^│]+]]) -- file name
        vim.fn.matchadd("Number", [[\v│\s*\zs\d+:\d+\ze\s*│]]) -- position
    end,
})
