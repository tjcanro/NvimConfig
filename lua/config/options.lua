local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.showmode = false

-- Use the system clipboard. On macOS this uses pbcopy/pbpaste automatically.
opt.clipboard = "unnamedplus"

opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 400

opt.splitright = true
opt.splitbelow = true
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.confirm = true
opt.termguicolors = true

opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.smartindent = true

opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

opt.inccommand = "split"
opt.completeopt = { "menu", "menuone", "noselect" }
