local utils = require("utils");

-- vim.keymap.set("i", "<C-j>", "<NOP>")
-- vim.keymap.set("i", "<C-k>", "<NOP>")
vim.keymap.set("i", "<C-j>", "<C-n>")
vim.keymap.set("i", "<C-k>", "<C-p>")
vim.cmd(":inoremap <expr> <cr> pumvisible() ? '<c-y>' : '<cr>'")
vim.cmd(":inoremap <expr> <Esc> pumvisible() ? '<c-e><Esc>' : '<Esc>'")
vim.keymap.set("c", "<C-k>", "<C-p>")
vim.keymap.set("c", "<C-j>", "<C-n>")
vim.cmd(":cnoremap <expr> <cr> pumvisible() ? '<c-y>' : '<cr>'")
vim.keymap.set("t", "<Esc><Esc>", function()
    vim.fn.feedkeys(vim.keycode("<C-\\><C-n>"))
    -- utils.closeFloatingWin()
end, { desc = "Exit terminal mode" })
vim.keymap.set("n", "<leader><leader>x", function() vim.cmd(":source %") end,
    { silent = true, desc = "Source current file" })
vim.keymap.set("n", "<leader>x", function() vim.cmd(":. lua") end,
    { silent = true, desc = "Execute current line" })
vim.keymap.set("n", "<C-s>", function() vim.cmd.w() end, { silent = true, desc = "Save file" })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
vim.keymap.set("n", "<ESC>", function() vim.cmd("nohlsearch") end, { desc = "Clear highlights on search" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Keeps the mouse in place while searching" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Keeps the mouse in place while searching" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Keeps the mouse in place while moving" }) -- Move half a page down (zz centers)
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Keeps the mouse in place while moving" }) -- Move half a page up (zz centers)
vim.keymap.set("n", "J", "mzJ`z", { desc = "Leaves the mouse in place while moving text" })
vim.keymap.set("v", "<", "<gv", { desc = "Indent text left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent text right" })
vim.keymap.set("v", "J", ":move '>+1<CR>gv=gv", { desc = "Move text down" })
vim.keymap.set("v", "K", ":move '<-2<CR>gv=gv", { desc = "Move text up" })
vim.keymap.set("x", "K", ":move '<-2<CR>gv=gv", { desc = "Move text up" })
vim.keymap.set("x", "J", ":move '>+1<CR>gv=gv", { desc = "Move text down" })
vim.keymap.set("x", "p", [["_dP]], { desc = "Dont save deletion on buffer on paste" })
vim.keymap.set("x", "p", '"_dP', { desc = "Paste on top of a word without copying" })
vim.keymap.set("v", "<leader>y", "\"+y", { desc = "Copy to system clipboard" })
vim.keymap.set("v", "p", '"_dP', { desc = "Paste on top of a word without copying" })
vim.keymap.set("v", "<leader>Y", "\"+Y", { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<leader>y", "\"+y", { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<leader>Y", "\"+Y", { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<A-Up>", function() vim.cmd(":resize -2") end, { desc = "Resize window up" })
vim.keymap.set("n", "<A-Down>", function() vim.cmd(":resize +2") end, { desc = "Resize window do wn" })
vim.keymap.set("n", "<A-Left>", function() vim.cmd(":vertical resize  +2") end,
    { desc = "Resize  window left" })
vim.keymap.set("n", "<A-Right>", function() vim.cmd(":vertical resize -2") end,
    { desc = "Resize window rigt" })
vim.keymap.set("n", "<C-w>r", "<C-w><C-r>", { desc = "Swap windows position" })
vim.keymap.set("n", "<leader>bp", function() vim.cmd(":bprevious") end, { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bn", function() vim.cmd(":bnext") end, { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bx", function() vim.cmd(":bd!") end, { desc = "Close buffers" })
vim.keymap.set("n", "<leader>bq", function()
    local current_buf = vim.api.nvim_get_current_buf()
    local count = 0
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if (current_buf ~= buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
            -- vim.api.nvim_buf_delete(buf, { unload = true })
            -- vim.api.nvim_buf_delete(buf, {})
            count = count + 1
        end
    end

    print("Closed " .. count .. " buffers")
end, { desc = "Closes other buffers, leaves current buffer open" })

vim.keymap.set("n", "<leader>sp", function() vim.cmd(":setlocal spell!") end, { desc = "Activate spell check" })
vim.keymap.set("n", "<leader>sr", function() vim.cmd(":spellr") end,
    { desc = "Repeat spell correction to matching words" })

vim.keymap.set("n", "<leader>cc", function()
    local message = vim.fn.input("Commit message: ")
    return {
        vim.cmd(":!git add . && git commit -m '" .. message .. "'"),
        vim.api.nvim_feedkeys("<cr>", "n", false),
        print("Commited: " .. message)
    }
end, { desc = "Quick commit" })

vim.keymap.set("n", "<leader>fo", function() vim.cmd.copen() end, { desc = "Open quickfix list" })
vim.keymap.set("n", "<leader>fq", function() vim.cmd.cclose() end, { desc = "Close quickfix list" })
vim.keymap.set("n", "<leader>fn", function() vim.cmd.cnext() end, { desc = "Goes to next quickfix list item" })
vim.keymap.set("n", "<leader>fp", function() vim.cmd.cprevious() end, { desc = "Goes to next quickfix list item" })
vim.keymap.set("n", "<A-n>", function() vim.cmd.cnext() end, { desc = "Goes to next quickfix list item" })
vim.keymap.set("n", "<A-p>", function() vim.cmd.cprevious() end, { desc = "Goes to next quickfix list item" })

vim.keymap.set("n", "<leader>cj", function()
    vim.cmd.cle()
    print("Cleared jump list")
end, { desc = "Clear jump list" })

vim.keymap.set("n", "<leader><CR>", function()
    utils:openTerminal()
end, { desc = "Opens terminal" })

vim.keymap.set("x", "<leader>r", function()
    local function getSelection()
        -- does not handle rectangular selection
        local s_start = vim.fn.getpos(".")
        local s_end = vim.fn.getpos("v")
        local lines = vim.fn.getregion(s_start, s_end)
        return lines
    end

    local selection = getSelection()
    local text = vim.fn.escape(selection[1], [[\/]])

    local clear_selection = vim.keycode("<C-u>")
    local double_left = vim.keycode("<Left><Left><Left>")
    local keys_to_feed = ":" .. clear_selection .. "%s/" .. text .. "//gc" .. double_left

    vim.fn.feedkeys(keys_to_feed)
end, { desc = "Replaces word under cursor" })

vim.keymap.set("n", "<leader>sc", function()
    buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_set_current_buf(buf)
end, { desc = "Opens scratch buffer" })

vim.keymap.set("n", "<leader>gs", function()
    utils:runOnTerminal({ cmd = "lazygit" })
end, { desc = "Run lazygit in a floating terminal" })
