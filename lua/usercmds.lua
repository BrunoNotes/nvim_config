local utils = require("utils");

vim.api.nvim_create_user_command("ChangeCWD", function()
    local file_cwd = vim.fn.expand("%:p:h")
    if (file_cwd ~= nil or file_cwd ~= "") then
        if string.sub(file_cwd, 1, 3) == "oil" then
            vim.fn.chdir(string.sub(file_cwd, 7, string.len(file_cwd)))
        else
            vim.fn.chdir(file_cwd)
        end
    end

    print(string.format("CWD changed to: %s", vim.loop.cwd()))
end, { desc = "Change current working directory", nargs = '*' })

vim.api.nvim_create_user_command("MakeFileExecutable", function()
    vim.cmd(":!chmod +x %")
end, { desc = "Make current file executable", nargs = '*' })

vim.api.nvim_create_user_command("GenEditorConfig", function()
    local editorconfig_path = vim.fn.getcwd() .. "/.editorconfig"

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

    local editorconfig = [[
[*]
indent_style = space
indent_size = 4
]]
    for _, ext in ipairs(exts) do
        if ext:lower() == "lua" then
            local lua_config = [[
# https://github.com/CppCXY/EmmyLuaCodeStyle/blob/master/lua.template.editorconfig
[*.lua]
# true/false or always
align_continuous_assign_statement = false
align_continuous_rect_table_field = false
# option none / always / contain_curly/
align_array_table = false
        ]]
            editorconfig = editorconfig .. lua_config
        elseif ext:lower() == "cs" then
            local cs_config = [[
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
            editorconfig = editorconfig .. cs_config
        end
    end

    utils.writeFile(editorconfig_path, editorconfig)
end, { desc = "Generate .editorconfig", nargs = '*' })

vim.api.nvim_create_user_command("Terminal", function(opts)
    -- print(vim.inspect(opts))
    -- utils:openTerminal()
    if utils.tableSize(opts.fargs) > 0 then
        for _, value in ipairs(opts.fargs) do
            value = value:lower()
            if value == "r" or value == "replace" then
                utils:openTerminal({ floating = false })
            elseif value == "v" or value == "vertical" then
                vim.cmd('vsplit')
                utils:openTerminal({ floating = false })
            elseif value == "s" or value == "horizontal" then
                vim.cmd('split')
                utils:openTerminal({ floating = false })
            else
                utils:openTerminal({ floating = true })
            end
        end
    else
        utils:openTerminal({ floating = true })
    end
end, {
    desc = "Opens terminal",
    nargs = "*",
    complete = function(ArgLead, CmdLine, CursorPos)
        local suggestions = {
            "replace",
            "vertical",
            "horizontal",
        }

        return vim.tbl_filter(function(item)
            return item:match("^" .. ArgLead)
        end, suggestions)
    end
})
