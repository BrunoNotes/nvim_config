local utils = require("utils");

vim.api.nvim_create_user_command("PrintLog", function()
    utils.printLog()
end, { desc = "Print log", nargs = '*' })

vim.api.nvim_create_user_command("ClearLog", function()
    utils.clearLog()
end, { desc = "Print log", nargs = '*' })

vim.api.nvim_create_user_command("ChangeCWD", function()
    utils:changeCWD(true)
end, { desc = "Change current working directory", nargs = '*' })

vim.api.nvim_create_user_command("MakeFileExecutable", function()
    if utils:current_os() == utils.os.linux then
        vim.cmd(":!chmod +x %")
    else
        print("Command not implemented for " .. utils:current_os())
    end
end, { desc = "Make current file executable", nargs = '*' })

vim.api.nvim_create_user_command("GenEditorConfig", function(opts)
    opts = opts or {}
    local config = {
        file = false,
        lua = false,
        csharp = false,
    }

    local no_args = true
    if opts.fargs ~= nil then
        for _, arg in ipairs(opts.fargs) do
            if arg == "file" then
                config.file = true
            elseif arg == "lua" or arg == "all" then
                config.lua = true
            elseif arg == "csharp" or arg == "all" then
                config.csharp = true
            end
        end
    end

    local editorconfig_path = vim.fn.getcwd() .. "/.editorconfig"

    if config.file then
        local files = utils:scanDir(vim.fn.getcwd())
        -- print(vim.inspect(files))

        local exts = {}

        -- print(vim.inspect(exts))
        for _, file in ipairs(files) do
            local ext = utils.getFileExt(file)
            if not utils.existsInTable(exts, ext) then
                table.insert(exts, ext)
            end
        end

        for _, ext in ipairs(exts) do
            if ext:lower() == "lua" then
                config.lua = true
            elseif ext:lower() == "cs" then
                config.csharp = true
            end
        end
    end

    local editorconfig = [[
[*]
indent_style = space
indent_size = 4
]]

    local lua_config = [[
# https://github.com/CppCXY/EmmyLuaCodeStyle/blob/master/lua.template.editorconfig
[*.lua]
# true/false or always
align_continuous_assign_statement = false
align_continuous_rect_table_field = false
# option none / always / contain_curly/
align_array_table = false
        ]]

    if config.lua then
        editorconfig = editorconfig .. lua_config
    end

    local csharp_config = [[
# https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/code-style-rule-options?view=vs-2019
[*.cs]
# New line preferences
csharp_new_line_before_open_brace = false
csharp_new_line_before_else = false
csharp_new_line_before_catch = false
csharp_new_line_before_finally = false
csharp_new_line_before_members_in_object_initializers = false
csharp_new_line_before_members_in_anonymous_types = false
csharp_new_line_between_query_expression_clauses = false
        ]]

    if config.csharp then
        editorconfig = editorconfig .. csharp_config
    end

    utils.writeFile(editorconfig_path, editorconfig)
end, {
    desc = "Generate .editorconfig",
    nargs = '*',
    complete = function(ArgLead, CmdLine, CursorPos)
        local suggestions = {
            "all",
            "file",
            "lua",
            "csharp"
        }

        return vim.tbl_filter(function(item)
            return item:match("^" .. ArgLead)
        end, suggestions)
    end
})

vim.api.nvim_create_user_command("Term", function()
    utils:openTerminal({})
end, {
    desc = "Opens terminal",
    nargs = "*"
})

vim.api.nvim_create_user_command("TermRun", function(opts)
    if utils.tableSize(opts.fargs) > 0 then
        local cmd_table = {}
        for _, value in ipairs(opts.fargs) do
            value = value:lower()
            table.insert(cmd_table, value)
        end
        local cmd = table.concat(cmd_table, " ")
        utils:sendCmdToTerminal(cmd)
    end
end, {
    desc = "Runs cmd on terminal",
    nargs = "*",
})
