local utils = require("utils");

local path = vim.fn.getcwd() .. "/.clang-format"

local text = [[
---
Language: C
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
    utils.writeFile(path, text)
end, { desc = "Generate .clang-format for C", nargs = '*' })
