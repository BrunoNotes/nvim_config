local utils = require("utils")
local icons = utils.icons

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

require("tokyonight").setup({
    style = "night",
    transparent = true,
    styles = {
        sidebars = "transparent",
        floats = "transparent",
    },
    sidebars = { "qf", "help" },
})

vim.cmd("colorscheme tokyonight")

require("oil").setup({
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

local ts_ok, nvim_treesitter = pcall(require, "nvim-treesitter")

nvim_treesitter.setup {
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

if ts_ok then
    -- fix bug, not starting for some languages
    local ts_installed_langs = nvim_treesitter.get_installed()
    local ts_available_langs = nvim_treesitter.get_available()

    vim.api.nvim_create_autocmd("FileType", {
        -- pattern = { "c", "cpp", "make", "cs" },
        group = vim.api.nvim_create_augroup("b_treesitter_start", { clear = true }),
        callback = function(args)
            local lang = vim.treesitter.language.get_lang(args.match)

            if not vim.list_contains(ts_installed_langs, lang) and vim.list_contains(ts_available_langs, lang) then
                -- print("Installing treesitter parser for " .. lang .. "...")
                -- nvim_treesitter.install(lang):wait()
                vim.schedule(function()
                    print("Installing treesitter parser for " .. lang .. "...")
                    nvim_treesitter.install(lang):wait()
                    pcall(vim.treesitter.start)
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

require("mason").setup()
require("mason-lspconfig").setup()

vim.lsp.config("lua_ls", {
    on_init = function(client)
        client.config.settings.Lua = vim.tbl_deep_extend(
            "force",
            client.config.settings.Lua,
            {
                -- Make the server aware of Neovim runtime files
                workspace = {
                    checkThirdParty = false,
                    library = {
                        vim.env.VIMRUNTIME
                    }
                    -- library = {
                    --   vim.api.nvim_get_runtime_file("", true),
                    -- }
                }
            })
    end,
    settings = {
        Lua = {}
    }
})

vim.g.zig_fmt_autosave = 0

vim.lsp.config("clangd", {
    cmd = { "clangd", "--header-insertion=never" }
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("b_lsp_attach", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then return end

        -- This stops the LSP from sending the "gray" tokens for inactive regions
        if client and client.name == "clangd" then
            client.server_capabilities.semanticTokensProvider = nil
        end
        vim.diagnostic.config({ underline = { severity = { min = vim.diagnostic.severity.HINT } } })
        vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {})

        vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end)
        vim.keymap.set("n", "H", function() vim.diagnostic.open_float() end)
        vim.keymap.set("i", "<C-S>", function() vim.lsp.buf.signature_help() end)
        vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end)
        vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end)
        vim.keymap.set("n", "gi", function() vim.lsp.buf.implementation() end)
        vim.keymap.set("n", "<F2>", function() vim.lsp.buf.rename() end)

        if client:supports_method("textDocument/completion") then
            -- adds completion to the default list (<C-x><C-o>)
            vim.lsp.completion.enable(
                true,
                client.id,
                args.buf,
                {
                    autotrigger = false
                }
            )
            -- vim.cmd("set completeopt+=noselect")
        end

        vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)

        -- vim.api.nvim_create_autocmd("BufWritePre", {
        --     desc = "Format on save",
        --     group = vim.api.nvim_create_augroup("b_lsp_format", { clear = true }),
        --     buffer = args.buf,
        --     callback = function()
        --         if client:supports_method("textDocument/formatting") then
        --             vim.lsp.buf.format({
        --                 bufnr = args.buf,
        --                 id = client.id,
        --                 timeout_ms = 1000
        --             })
        --         end
        --     end,
        -- })
    end
})

vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = icons.error,
            [vim.diagnostic.severity.WARN] = icons.warn,
            [vim.diagnostic.severity.HINT] = icons.hint,
            [vim.diagnostic.severity.INFO] = icons.info,
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
                return string.format("%s %s", icons.error, diagnostic.message)
            end
            if diagnostic.severity == vim.diagnostic.severity.WARN then
                return string.format("%s %s", icons.warn, diagnostic.message)
            end
            if diagnostic.severity == vim.diagnostic.severity.INFO then
                return string.format("%s %s", icons.info, diagnostic.message)
            end
            if diagnostic.severity == vim.diagnostic.severity.HINT then
                return string.format("%s %s", icons.hint, diagnostic.message)
            end
            return diagnostic.message
        end,
    },
})

require("telescope").setup {
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

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>.", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>gp", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>gb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>gh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>gl", builtin.resume, { desc = "Telescope open last picker" })

local cmp = require("blink.cmp")
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
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = false },
    },
    cmdline = {
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
