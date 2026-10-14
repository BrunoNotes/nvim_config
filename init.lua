vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = "a"
vim.o.showmode = true
vim.opt.swapfile = false
vim.opt.undofile = false
vim.opt.colorcolumn = "80"
vim.opt.signcolumn = "yes"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 50
vim.opt.inccommand = "split"
vim.opt.errorbells = false
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.hlsearch = true
vim.opt.scrolloff = 10
vim.opt.breakindent = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", multispace = "·", nbsp = "␣" }
vim.opt.confirm = true
vim.opt.winborder = "rounded"
vim.opt.timeoutlen = 300
-- vim.opt.spell = true
vim.opt.spelllang = "pt_br,en_us,cjk"
vim.opt.completeopt = "fuzzy,menu,menuone,noselect,noinsert,popup,nosort"
vim.opt.complete = "F,kspell,o,."
vim.opt.wildoptions = "fuzzy,pum,tagfile"

vim.cmd([[set errorformat+=%f(%l:%c)\ %m]]) -- to parse odin error path in quickfix list

vim.o.clipboard = ""
-- vim.o.clipboard = "unnamedplus"

local utils = require("utils")

if utils:current_os() == utils.os.windows then
    if vim.fn.executable('pwsh') == 1 then
        vim.o.shell = 'pwsh'
    else
        vim.o.shell = 'powershell'
    end
    vim.o.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    vim.o.shellquote = ""
    vim.o.shellxquote = ""
end

require("keymap")

require("autocmds")

require("usercmds")

-- default auto complete
-- require("auto_complete")

require("plugins")

vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = utils.icons.error,
            [vim.diagnostic.severity.WARN] = utils.icons.warn,
            [vim.diagnostic.severity.HINT] = utils.icons.hint,
            [vim.diagnostic.severity.INFO] = utils.icons.info,
        },
    },
    -- virtual_lines or virtual_text
    -- underline = false,
    virtual_text = {
        -- source = "always",  -- Or "if_many"
        severity = vim.diagnostic.severity.ERROR,
        spacing = 10,
        prefix = "",
        sufix = "",
        format = function(diagnostic)
            if diagnostic.severity == vim.diagnostic.severity.ERROR then
                return string.format("%s %s", utils.icons.error, diagnostic.message)
            end
            if diagnostic.severity == vim.diagnostic.severity.WARN then
                return string.format("%s %s", utils.icons.warn, diagnostic.message)
            end
            if diagnostic.severity == vim.diagnostic.severity.INFO then
                return string.format("%s %s", utils.icons.info, diagnostic.message)
            end
            if diagnostic.severity == vim.diagnostic.severity.HINT then
                return string.format("%s %s", utils.icons.hint, diagnostic.message)
            end
            return diagnostic.message
        end,
    },
})

if vim.g.neovide then
end
