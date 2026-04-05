return {
    'nvim-telescope/telescope.nvim',
    tag = 'v0.2.0',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        require('telescope').setup {
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

        local builtin = require('telescope.builtin')

        vim.keymap.set('n', '<leader>.', builtin.find_files, { desc = 'Telescope find files' })
        vim.keymap.set('n', '<leader>gp', builtin.live_grep, { desc = 'Telescope live grep' })
        vim.keymap.set('n', '<leader>gb', builtin.buffers, { desc = 'Telescope buffers' })
        vim.keymap.set('n', '<leader>gh', builtin.help_tags, { desc = 'Telescope help tags' })
    end
}
