-- csharp
local utils = require("utils");

local path = vim.fn.getcwd() .. "/odinfmt.json"

local odinfmt_json = [[
{
    "$schema": "https://raw.githubusercontent.com/DanielGavin/ols/master/misc/odinfmt.schema.json",
    "character_width": 80,
    "tabs": false,
    "spaces": 4
}
]]

vim.api.nvim_create_user_command("GenOdinFmtJson", function()
    utils.writeFile(path, odinfmt_json)
end, { desc = "Generate odinfmt.json", nargs = '*' })
