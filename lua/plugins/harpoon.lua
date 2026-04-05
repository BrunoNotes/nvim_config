return {
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            -- require("plugins.config.harpoon-rc")
            local harpoon = require("harpoon")

            harpoon:setup({
                settings = {
                    save_on_toggle = true,
                    sync_on_ui_close = true
                }
            })

            vim.keymap.set("n", "<leader>hf", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
            vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end)
            vim.keymap.set("n", "<leader>hn", function()
                local win = vim.api.nvim_get_current_win()
                if vim.api.nvim_win_get_config(win).relative == '' then
                    -- if not floating
                    harpoon:list():next()
                end
            end)
            vim.keymap.set("n", "<leader>hp", function()
                local win = vim.api.nvim_get_current_win()
                if vim.api.nvim_win_get_config(win).relative == '' then
                    -- if not floating
                    harpoon:list():prev()
                end
            end)

            for _, n in ipairs({ 1, 2, 3, 4, 5 }) do
                vim.keymap.set(
                    "n",
                    "<leader>" .. n,
                    function()
                        local win = vim.api.nvim_get_current_win()
                        if vim.api.nvim_win_get_config(win).relative == '' then
                            -- if not floating
                            harpoon:list():select(n)
                        end
                    end,
                    { silent = true, desc = "Harpoon: go to list " .. n }
                )
            end
        end,

    }
}
