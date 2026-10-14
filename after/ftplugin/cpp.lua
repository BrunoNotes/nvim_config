local utils = require("utils");

local text = [[
---
Language:        Cpp
AllowShortFunctionsOnASingleLine: None
ColumnLimit: 80
IndentWidth: 4
UseTab: Never
PointerAlignment: Left
SortIncludes: false
BreakBeforeBraces: Attach
AlignAfterOpenBracket: BlockIndent
BinPackParameters: false
AllowAllParametersOfDeclarationOnNextLine: true
]]

vim.api.nvim_create_user_command("GenClangFormat", function()
    local path = vim.fn.getcwd() .. utils.path_char .. ".clang-format"
    local in_path = vim.fn.input("Path: ", path)
    utils.writeFile(in_path, text)
end, { desc = "Generate .clang-format for C++", nargs = '*' })

vim.lsp.config("clangd", {
    cmd = { "clangd", "--header-insertion=never" }
})
