local M = {}

local views = {}

local function set_lines(buf, lines)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function refresh(buf)
  local view = views[buf]
  if not view or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  if view.job then
    pcall(view.job.kill, view.job, 15)
  end

  set_lines(buf, { "Loading remote Git diff…" })
  local command = ("git -C %s diff --no-ext-diff --no-color --find-renames --unified=%d HEAD --"):format(
    vim.fn.shellescape(view.remote.path),
    view.context
  )

  view.job = vim.system({ "ssh", view.remote.host, command }, { text = true }, function(result)
    vim.schedule(function()
      if not views[buf] or not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      local output = result.stdout or ""
      local lines = vim.split(output, "\n", { plain = true })
      if lines[#lines] == "" then
        table.remove(lines)
      end
      if result.code ~= 0 then
        local error_text = vim.trim(result.stderr or "")
        lines = { error_text ~= "" and error_text or "Unable to load the remote Git diff" }
      elseif #lines == 0 then
        lines = { "Remote working tree has no tracked changes relative to HEAD." }
      end

      set_lines(buf, lines)
      vim.bo[buf].modified = false
    end)
  end)
end

local function close(buf)
  local view = views[buf]
  if not view then
    return false
  end
  if view.job then
    pcall(view.job.kill, view.job, 15)
  end
  views[buf] = nil

  if view.tab and vim.api.nvim_tabpage_is_valid(view.tab) and #vim.api.nvim_list_tabpages() > 1 then
    vim.api.nvim_set_current_tabpage(view.tab)
    vim.cmd("tabclose")
    if view.origin_win and vim.api.nvim_win_is_valid(view.origin_win) then
      vim.api.nvim_set_current_win(view.origin_win)
    end
  elseif vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  return true
end

local function current_diff_file(buf)
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(buf, 0, cursor, false)
  for index = #lines, 1, -1 do
    local old_path, new_path = lines[index]:match("^diff %-%-git a/(.-) b/(.-)$")
    if old_path and new_path then
      return new_path ~= "/dev/null" and new_path or old_path
    end
  end
end

local function open_current_file(buf)
  local view = views[buf]
  local relative = view and current_diff_file(buf)
  if not view or not relative then
    return
  end

  local remote_url = require("config.remote_live_grep").remote_url(view.remote, relative)
  local target_win = view.origin_win
  if not target_win or not vim.api.nvim_win_is_valid(target_win) then
    vim.cmd("tabprevious")
    target_win = vim.api.nvim_get_current_win()
  end
  vim.api.nvim_set_current_win(target_win)
  require("async-remote-write.operations").simple_open_remote_file(remote_url, nil, target_win)
  require("config.remote_tree_follow").reveal(remote_url)
end

function M.open(session)
  local remote = require("async-remote-write.utils").parse_remote_path(session.url)
  if not remote then
    vim.notify("Unable to determine the active remote repository", vim.log.levels.ERROR)
    return
  end

  M.close()
  local origin_win = vim.api.nvim_get_current_win()
  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, ("Remote Git Diff: %s:%s"):format(remote.host, remote.path))
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].modifiable = false
  vim.wo.winbar = " Remote Git Diff  [R] refresh  [+/-] context  [Enter] open file  [q] close "

  views[buf] = {
    remote = remote,
    origin_win = origin_win,
    tab = vim.api.nvim_get_current_tabpage(),
    context = 3,
  }
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      local view = views[buf]
      if view and view.job then
        pcall(view.job.kill, view.job, 15)
      end
      views[buf] = nil
    end,
  })
  vim.keymap.set("n", "q", function()
    close(buf)
  end, { buffer = buf, desc = "Close remote Git diff" })
  vim.keymap.set("n", "R", function()
    refresh(buf)
  end, { buffer = buf, desc = "Refresh remote Git diff" })
  vim.keymap.set("n", "+", function()
    views[buf].context = views[buf].context + 5
    refresh(buf)
  end, { buffer = buf, desc = "Add diff context" })
  vim.keymap.set("n", "-", function()
    views[buf].context = math.max(0, views[buf].context - 5)
    refresh(buf)
  end, { buffer = buf, desc = "Reduce diff context" })
  vim.keymap.set("n", "]c", function()
    vim.fn.search("^@@", "W")
  end, { buffer = buf, desc = "Next remote diff hunk" })
  vim.keymap.set("n", "[c", function()
    vim.fn.search("^@@", "bW")
  end, { buffer = buf, desc = "Previous remote diff hunk" })
  vim.keymap.set("n", "<CR>", function()
    open_current_file(buf)
  end, { buffer = buf, desc = "Open remote diff file" })

  refresh(buf)
end

function M.close()
  for buf in pairs(views) do
    return close(buf)
  end
  return false
end

return M
