vim.pack.add({
    "https://github.com/folke/tokyonight.nvim",
    "https://github.com/echasnovski/mini.icons",
    "https://github.com/stevearc/oil.nvim",
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/mason-org/mason.nvim",
    "https://github.com/mason-org/mason-lspconfig.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/nvim-telescope/telescope.nvim",
    "https://github.com/saghen/blink.lib",
    "https://github.com/Saghen/blink.cmp",
})

local hooks = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind

    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
        if not ev.data.active then
            vim.cmd.packadd("nvim-treesitter")
        end
        vim.cmd(":TSUpdate")
    end
end

vim.api.nvim_create_autocmd("PackChanged", { callback = hooks })

vim.cmd.packadd("nvim.undotree")
vim.cmd.packadd("nvim.difftool")

local tokyonight_ok, tokyonight = pcall(require, "tokyonight")
if tokyonight_ok then
    tokyonight.setup({
        style = "night",
        transparent = true,
        styles = {
            sidebars = "transparent",
            floats = "transparent",
        },
        sidebars = { "qf", "help" },
    })

    vim.cmd("colorscheme tokyonight")
end

local oil_ok, oil = pcall(require, "oil")
if oil_ok then
    oil.setup({
        default_file_explorer = true,
        columns = {
            "icon",
        },
        keymaps = {
            ["g?"] = "actions.show_help",
            ["<F1>"] = "actions.show_help",
            ["<CR>"] = "actions.select",
            ["<C-s>"] = ":w<cr>",
            ["<C-p>"] = "actions.preview",
            ["<C-c>"] = "actions.close",
            ["<ESC>"] = "actions.close",
            ["<C-r>"] = "actions.refresh",
            ["-"] = "actions.parent",
            ["_"] = "actions.open_cwd",
            ["`"] = "actions.cd",
            ["~"] = "actions.tcd",
            ["gs"] = "actions.change_sort",
            ["gx"] = "actions.open_external",
            ["g."] = "actions.toggle_hidden",
            ["g\\"] = "actions.toggle_trash",
        },
    })

    vim.keymap.set("n", "<leader>fb", function() vim.cmd("Oil") end, { silent = true, desc = "Opens file browser" })
end

local ts_ok, ts = pcall(require, "nvim-treesitter")

if ts_ok then
    ts.setup {
        ensure_installed = {},
        sync_install = false,
        auto_install = true,
        ignore_install = {},
        highlight = {
            enable = true,
            disable = function(lang, buf)
                local max_filesize = 20000 * 1024 -- 20 mb
                local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                if ok and stats and stats.size > max_filesize then
                    return true
                end
            end,
            additional_vim_regex_highlighting = false,
        },
    }

    -- fix bug, not starting for some languages
    local ts_installed_langs = ts.get_installed()
    local ts_available_langs = ts.get_available()

    vim.api.nvim_create_autocmd("FileType", {
        -- pattern = { "c", "cpp", "make", "cs" },
        group = vim.api.nvim_create_augroup("b_treesitter_start", { clear = true }),
        callback = function(args)
            local lang = vim.treesitter.language.get_lang(args.match)

            if not vim.list_contains(ts_installed_langs, lang) and vim.list_contains(ts_available_langs, lang) then
                print("Installing treesitter parser for " .. lang)

                ts.install(lang):await(function()
                    vim.schedule(function()
                        pcall(vim.treesitter.start)
                        print("Treesitter parser for " .. lang .. " installed successfully!")
                    end)
                end)
            else
                vim.schedule(function()
                    pcall(vim.treesitter.start)
                end)
            end
        end,
    })
    vim.cmd("syntax off")
end

--[[
language specific config is in the after folder
:help lspconfig-all

- Notes:
    - for C# use roslyn_ls (started in the after folder)
]]
local mason_ok, mason = pcall(require, "mason")
if mason_ok then
    mason.setup()

    local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")

    if mason_lspconfig_ok then
        mason_lspconfig.setup()
    end
end

local telescope_ok, telescope = pcall(require, "telescope")
if telescope_ok then
    telescope.setup {
        defaults = {
            mappings = {
                i = {
                    ["<C-j>"] = require("telescope.actions").move_selection_next,
                    ["<C-k>"] = require("telescope.actions").move_selection_previous,
                },
                n = {
                    ["<C-j>"] = require("telescope.actions").move_selection_next,
                    ["<C-k>"] = require("telescope.actions").move_selection_previous,
                }
            },
            preview = false,
        },
        pickers = {
            find_files = {
                theme = "ivy",
            },
            live_grep = {
                theme = "ivy",
            },
            buffers = {
                theme = "ivy",
            },
            help_tags = {
                theme = "ivy",
            },
        },
        extensions = {
        }
    }
end

local telescope_builtin_ok, telescope_builtin = pcall(require, "telescope.builtin")
if telescope_builtin_ok then
    vim.keymap.set("n", "<leader>.", telescope_builtin.find_files, { desc = "Telescope find files" })
    vim.keymap.set("n", "<leader>gp", telescope_builtin.live_grep, { desc = "Telescope live grep" })
    vim.keymap.set("n", "<leader>gb", telescope_builtin.buffers, { desc = "Telescope buffers" })
    vim.keymap.set("n", "<leader>gh", telescope_builtin.help_tags, { desc = "Telescope help tags" })
    vim.keymap.set("n", "<leader>gl", telescope_builtin.resume, { desc = "Telescope open last picker" })
end

local cmp_ok, cmp = pcall(require, "blink.cmp")
if cmp_ok then
    cmp.build():pwait()
    cmp.setup({
        completion = {
            list = { selection = { preselect = false, auto_insert = false } },
            menu = {
                auto_show = false,
                border = "none",
                draw = {
                    columns = { { "label", "label_description", gap = 1 }, { "kind_icon" } }
                },
            },
            documentation = { auto_show = true, auto_show_delay_ms = 100 },
            ghost_text = { enabled = false },
        },
        cmdline = {
            enabled = true,
            keymap = {
                preset = 'none',
                ["<C-y>"] = { "select_and_accept", "fallback" },
                ["<CR>"] = { "select_and_accept", "fallback" },

                ["<C-k>"] = { "show", "select_prev", "fallback_to_mappings" },
                ["<C-j>"] = { "show", "select_next", "fallback_to_mappings" },

                ["<S-Tab>"] = { "show", "select_prev", "fallback_to_mappings" },
                ["<Tab>"] = { "show", "select_next", "fallback_to_mappings" },
            }
        },
        -- Insert/Select mode
        keymap = {
            preset = "none",
            ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<C-e>"] = { "hide", "fallback" },
            ["<C-y>"] = { "select_and_accept", "fallback" },
            ["<CR>"] = { "select_and_accept", "fallback" },

            ["<C-k>"] = { "show", "select_prev", "fallback_to_mappings" },
            ["<C-j>"] = { "show", "select_next", "fallback_to_mappings" },

            ["<C-b>"] = { "scroll_documentation_up", "fallback" },
            ["<C-f>"] = { "scroll_documentation_down", "fallback" },

            ["<Tab>"] = { "snippet_forward", "fallback" },
            ["<S-Tab>"] = { "snippet_backward", "fallback" },

            -- ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
        },
    })
end
