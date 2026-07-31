-- csharp
local utils = require("utils");

local omnisharp_path = vim.fn.getcwd() .. "/omnisharp.json"

local omnisharp_json = [[
{
    "FormattingOptions": {
        "NewLinesForBracesInLambdaExpressionBody": false,
        "NewLinesForBracesInAnonymousMethods": false,
        "NewLinesForBracesInAnonymousTypes": false,
        "NewLinesForBracesInControlBlocks": false,
        "NewLinesForBracesInTypes": false,
        "NewLinesForBracesInMethods": false,
        "NewLinesForBracesInProperties": false,
        "NewLinesForBracesInObjectCollectionArrayInitializers": false,
        "NewLinesForBracesInAccessors": false,
        "NewLineForElse": false,
        "NewLineForCatch": false,
        "NewLineForFinally": false
    }
}
]]

vim.api.nvim_create_user_command("GenOmnisharpJson", function()
    utils.writeFile(omnisharp_path, omnisharp_json)
end, { desc = "Generate omnisharp.json for C#", nargs = '*' })

-- C#
-- dotnet tool install --global roslyn-language-server --prerelease
local ok_lsp, _ = pcall(vim.lsp.enable, "roslyn_ls")
if not ok_lsp then
    print("Unable to start language server")
end
