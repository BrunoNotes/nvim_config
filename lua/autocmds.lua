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
            if string.sub(file_cwd, 1, 3) == "oil" then
                vim.fn.chdir(string.sub(file_cwd, 7, string.len(file_cwd)))
            else
                vim.fn.chdir(file_cwd)
            end
        end

        print(string.format("CWD changed to: %s", vim.loop.cwd()))
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

vim.api.nvim_create_autocmd({ "TermOpen" }, {
    desc = "Terminal local options",
    group = vim.api.nvim_create_augroup("b_custom_term_open", {}),
    callback = function(buf)
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.scrolloff = 0
    end,
})

local statusBar = function()
    local getFileName = function()
        -- local file_path = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
        -- return string.format('%s', file_path)
        return vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
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
        local lsp_clients = vim.lsp.get_clients()

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
                return string.format('%s %s', icons.Constructor, lsp_names)
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

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "LspAttach" }, {
    desc = "Status line",
    group = vim.api.nvim_create_augroup("b_status_line", { clear = true }),
    callback = statusBar,
})
