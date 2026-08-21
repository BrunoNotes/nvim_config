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

vim.schedule(function()
    vim.o.clipboard = ""
    -- vim.o.clipboard = "unnamedplus"
end)

local utils = require("utils")
if utils.os_name == "Windows_NT" then
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
