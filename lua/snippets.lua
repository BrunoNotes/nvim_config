local utils = require("utils")

local getSnippets = function()
    local path = utils.nvim_config .. "/snippets"
    local pkg = utils:readJson(path .. "/package.json")
    local snippets = vim.tbl_get(pkg, 'contributes', 'snippets')

    local snip_lang_path = {} ---@type table<string, string[]>
    for _, s in ipairs(snippets) do
        local langs = s.language or {}
        langs = type(langs) == 'string' and { langs } or langs
        ---@cast langs string[]
        for _, lang in ipairs(langs) do
            snip_lang_path[lang] = snip_lang_path[lang] or {}
            table.insert(snip_lang_path[lang], vim.fs.normalize(vim.fs.joinpath(path, s.path)))
        end
    end

    return snip_lang_path
end

function _G.custom_complete(findstart, base)
    if findstart == 1 then
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]

        while col > 0 and line:sub(col, col):match('%w') do
            col = col - 1
        end

        return col
    else
        local candidates = {}

        local words = {}

        local snippets_path = getSnippets()
        if snippets_path[vim.bo.filetype] ~= nil then
            for _, paths in pairs(snippets_path[vim.bo.filetype]) do
                local lang_snippet = utils:readJson(paths)
                for name, _ in pairs(lang_snippet) do
                    table.insert(words, name)
                end
            end
        end

        for _, word in ipairs(words) do
            if word:match('^' .. base) then
                table.insert(candidates, {
                    word = word,
                    kind = "Snippet",
                    menu = "[Custom]"
                })
            end
        end

        return candidates
    end
end

-- set the user func to be the snippets <C-x><C-U>
vim.opt.completefunc = 'v:lua.custom_complete'

vim.api.nvim_create_autocmd({ "CompleteDone" }, {
    desc = "Snippets",
    -- buffer = vim.api.nvim_get_current_buf(),
    group = vim.api.nvim_create_augroup("b_snippets", { clear = true }),
    callback = function()
        local completed_item = vim.api.nvim_get_vvar("completed_item")
        if completed_item.kind ~= nil and completed_item.menu == "[Custom]" and completed_item.kind == "Snippet" then
            local snippet = nil
            local snippets_path = getSnippets()
            for _, paths in pairs(snippets_path[vim.bo.filetype]) do
                local lang_snippet = utils:readJson(paths)
                if lang_snippet[completed_item.word] ~= nil then
                    snippet = lang_snippet[completed_item.word]
                    break
                end
            end

            if snippet ~= nil then
                local body = ""
                for _, value in pairs(snippet.body) do
                    if body == "" then
                        body = value
                    else
                        body = body .. "\n" .. value
                    end
                end

                vim.cmd('normal! b')
                local current_pos = vim.fn.getpos('.')
                vim.cmd('normal! diw')
                vim.fn.setpos('.', current_pos)
                vim.snippet.expand(body)
            end
        end
    end,
})
