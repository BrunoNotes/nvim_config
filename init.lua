----- options -----

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
vim.opt.complete = "o"

vim.schedule(function()
    vim.o.clipboard = ""
    -- vim.o.clipboard = "unnamedplus"
end)

----- keymaps -----
require("keymaps")

----- autocommands -----
require("autocmds")

----- user commands -----
require("usercmds")

require("snippets")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
    spec = {
        -- import your plugins
        { import = "plugins" },
    },
    -- Configure any other settings here. See the documentation for more details.
    -- colorscheme that will be used when installing plugins.
    install = { colorscheme = { "habamax" } },
    -- automatically check for plugin updates
    checker = { enabled = false },
    change_detection = {
        enabled = false,
    },
})
