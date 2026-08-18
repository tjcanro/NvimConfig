local group = vim.api.nvim_create_augroup("personal_config", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Briefly highlight yanked text",
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = group,
  desc = "Keep splits evenly sized after a terminal resize",
  command = "tabdo wincmd =",
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group,
  desc = "Reload files changed by an external agent",
  command = "checktime",
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "rust", "python", "c", "cpp", "cmake" },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
    vim.bo.shiftwidth = 4
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "go",
  callback = function()
    vim.bo.expandtab = false
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 0
    vim.bo.shiftwidth = 4
  end,
})
