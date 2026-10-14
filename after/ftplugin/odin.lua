-- csharp
local utils = require("utils");

local odinfmt_json = [[
{
    "$schema": "https://raw.githubusercontent.com/DanielGavin/ols/master/misc/odinfmt.schema.json",
    "character_width": 80,
    "tabs": false,
    "spaces": 4
}
]]

vim.api.nvim_create_user_command("GenOdinFmtJson", function()
    local path = vim.fn.getcwd() .. utils.path_char .. "odinfmt.json"
    local in_path = vim.fn.input("Path: ", path)
    utils.writeFile(in_path, odinfmt_json)
end, { desc = "Generate odinfmt.json", nargs = '*' })
