local utils = require("utils")
local _snippets = {}

local getSnippetsPath = function()
    local path = utils.nvim_config .. utils.path_char .. "snippets"
    local pkg = utils:readJson(path .. utils.path_char .. "package.json")
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

local getSnippets = function(filetype)
    if _snippets[filetype] == nil then
        _snippets[filetype] = {}
        local snippets_path = getSnippetsPath()
        if snippets_path[filetype] ~= nil then
            for _, paths in pairs(snippets_path[filetype]) do
                local path = paths:gsub("%/", utils.path_char)
                local lang_snippet = utils:readJson(path)
                table.insert(_snippets[filetype], lang_snippet)
            end
        end
    end

    return _snippets[filetype] or {}
end


local lineHasPath = function(line)
    return utils.stringEndsWith(line, utils.path_char)
end

local getPathFromLine = function(line)
    local result = {}
    result.path = ""
    result.path_idx = 0

    local line_len = line:len()

    local idx = 0
    local is_path = true

    while idx < line_len do
        local sub = line:sub(line_len - idx, line_len)
        if utils.stringStartsWith(sub, ".") or utils.stringStartsWith(sub, utils.path_char) then
            if is_path then
                result.path = sub
                result.path_idx = idx
            end
        else
            is_path = false
            local before_word_idx = line_len - idx - 1
            if before_word_idx >= 1 then
                local sub_2 = line:sub(before_word_idx, line_len)

                if utils.stringStartsWith(sub_2, ".") or utils.stringStartsWith(sub_2, utils.path_char) then
                    is_path = true
                end
            end
        end
        idx = idx + 1
    end

    if result.path_idx > 0 then
        return result
    else
        return nil
    end
end

function _G.customComplete(findstart, base)
    if findstart == 1 then
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]

        while col > 0 and line:sub(col, col):match('%w') do
            col = col - 1
        end

        return col
        -- return vim.lsp.omnifunc(findstart, base)
    else
        local candidates = {}
        local line = vim.api.nvim_get_current_line()

        if lineHasPath(line) then
            local line_path = getPathFromLine(line)
            local path = base
            if line_path then
                path = line_path.path
            end
            local files = vim.fn.glob(path .. "*", false, true)
            -- local files = vim.fn.glob(base .. "*", false, true)
            for _, file in ipairs(files) do
                local is_dir = vim.fn.isdirectory(file) == 1
                local file_name = file:gsub(path, "")
                local display_name = file_name .. (is_dir and utils.path_char or "")

                table.insert(candidates, {
                    word = display_name,
                    abbr = display_name,
                    menu = "[Path]",
                    kind = is_dir and "D" or "F"
                })
            end
            if #candidates > 0 then return candidates end
        end

        local lsp_matches = vim.lsp.omnifunc(findstart, base)

        if type(lsp_matches) ~= "table" then
            lsp_matches = {}
        end

        -- local candidates = lsp_matches.words or lsp_matches

        local lsp_list = lsp_matches.words or lsp_matches
        for _, match in ipairs(lsp_list) do
            table.insert(candidates, match)
        end

        if vim.wo.spell then
            local spell_suggestions = vim.fn.spellsuggest(base, 25)
            for _, word in ipairs(spell_suggestions) do
                table.insert(candidates, {
                    word = word,
                    abbr = word,
                    menu = '[Spell]',
                    kind = 'W'
                })
            end
        end

        local snippets = getSnippets(vim.bo.filetype)

        for _, snippet in pairs(snippets) do
            for word, imp in pairs(snippet) do
                if base ~= "" and word:match("^" .. base) then
                    table.insert(candidates, {
                        word = word,
                        abbr = word,
                        kind = "S",
                        menu = "[Snippet]",
                        info = table.concat(imp.body, "\n"),
                    })
                end
            end
        end

        return candidates
    end
end

-- set the user func to be the snippets <C-x><C-U>
vim.opt.completefunc = 'v:lua.customComplete'

vim.api.nvim_create_autocmd({ "CompleteDone" }, {
    desc = "Snippets",
    -- buffer = vim.api.nvim_get_current_buf(),
    group = vim.api.nvim_create_augroup("b_snippets", { clear = true }),
    callback = function()
        local completed_item = vim.api.nvim_get_vvar("completed_item")
        if completed_item.kind ~= nil then
            if completed_item.menu == "[Snippet]"
                and completed_item.kind == "S"
            then
                local snippet = nil
                local snippets_json = getSnippets(vim.bo.filetype)
                for _, snp in pairs(snippets_json) do
                    if snp[completed_item.word] ~= nil then
                        snippet = snp[completed_item.word]
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
        end
    end,
})
