return {
    'stevearc/oil.nvim',
    dependencies = {
        {
            'echasnovski/mini.icons',
            opts = {}
        },
    },
    config = function()
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
    end
}
