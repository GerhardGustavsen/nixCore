local map = vim.keymap.set
local opts = {noremap = true, silent = true}

map("n", "<Space>", "", opts) -- Leader key
vim.g.mapleader = " "

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", opts)
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", opts)
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", opts)
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", opts)

-- File explorer toggle (kept)
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", opts)

-- Window navigation
map("n", "<Tab>", "<cmd>wincmd w<CR>", opts) -- next window

-- ESC: focus/open NvimTree
map(
    "n",
    "<Esc>",
    function()
        -- if the tree is visible, just focus it; otherwise open + focus
        local ok, view = pcall(require, "nvim-tree.view")
        if ok and view.is_visible() then
            vim.cmd("NvimTreeFocus")
        else
            vim.cmd("NvimTreeOpen | NvimTreeFocus")
        end
    end,
    {noremap = true, silent = true, desc = "Focus (or open) NvimTree"}
)

-- replace default "substitute char" with format+save
map(
    "n",
    "s",
    function()
        require("conform").format({async = false, lsp_fallback = true})
        vim.cmd("silent! write")
    end,
    {desc = "Format + Save", noremap = true, silent = true}
)
