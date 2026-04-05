return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
        config = function()
            require("tokyonight").setup({
                style = "night",
                transparent = true,
                styles = {
                    sidebars = "transparent",
                    floats = "transparent",
                },
                sidebars = { "qf", "help" },
                -- on_highlights = function(hl, c)
                --     hl.DiagnosticUnnecessary = {
                --         fg = c.text,
                --     }
                -- end,
            })

            vim.cmd("colorscheme tokyonight")
        end
    }
}
