local map = vim.keymap.set
local bottom_terminal_height = 10

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>confirm quit<CR>", { desc = "Quit window" })

map("n", "<C-h>", "<C-w><C-h>", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Focus right window" })

map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
map("n", "<leader>de", vim.diagnostic.open_float, { desc = "Diagnostic details" })
map("n", "<leader>dq", vim.diagnostic.setloclist, { desc = "Diagnostics to location list" })

map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })

local function toggle_bottom_terminal()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].bottom_terminal then
      vim.api.nvim_win_close(win, true)
      return
    end
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].bottom_terminal then
      local job = vim.b[buf].terminal_job_id
      if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
        vim.cmd(("botright %dsplit"):format(bottom_terminal_height))
        vim.api.nvim_win_set_buf(0, buf)
        vim.cmd.startinsert()
        return
      end
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  vim.cmd(("botright %dnew"):format(bottom_terminal_height))
  vim.cmd.terminal()
  vim.b.bottom_terminal = true
  vim.bo.bufhidden = "hide"
  vim.cmd.startinsert()
end

vim.api.nvim_create_user_command("BottomTerminalToggle", toggle_bottom_terminal, {
  desc = "Toggle the reusable bottom terminal",
})

local function toggle_context_terminal()
  local ok, session_manager = pcall(require, "remote-session.session_manager")
  if ok and session_manager.get_active_session_id() then
    vim.cmd("RemoteTerminalToggle")
    return
  end

  toggle_bottom_terminal()
end

map({ "n", "t" }, "<leader>~", toggle_context_terminal, { desc = "Toggle local or remote terminal" })
