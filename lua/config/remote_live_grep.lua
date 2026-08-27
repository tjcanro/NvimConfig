local M = {}

local preview_namespace = vim.api.nvim_create_namespace("RemoteLiveGrepPreview")

local function remote_url(remote, relative_path)
  local root = remote.path:gsub("^/", ""):gsub("/$", "")
  local relative = relative_path:gsub("^%./", "")
  return ("%s://%s/%s/%s"):format(remote.protocol, remote.host, root, relative)
end

local function remote_command(remote, command)
  return {
    "ssh",
    remote.host,
    ("cd %s && %s"):format(vim.fn.shellescape(remote.path), command),
  }
end

local function git_grep_command(remote, prompt)
  if not prompt or prompt == "" then
    return nil
  end

  local case_flag = prompt:lower() == prompt and "--ignore-case " or ""
  local command = ("git grep --line-number --column %s--no-color -I -e %s -- ."):format(
    case_flag,
    vim.fn.shellescape(prompt)
  )
  return remote_command(remote, command)
end

local function remote_previewer(remote)
  local previewers = require("telescope.previewers")

  return previewers.new_buffer_previewer({
    teardown = function(self)
      local job = self.state and self.state.remote_preview_job
      if job then
        pcall(job.kill, job, 15)
      end
    end,
    define_preview = function(self, entry)
      if not entry or not entry.filename or not entry.lnum then
        return
      end

      local previous = self.state.remote_preview_job
      if previous then
        pcall(previous.kill, previous, 15)
      end

      self.state.remote_preview_generation = (self.state.remote_preview_generation or 0) + 1
      local generation = self.state.remote_preview_generation
      local first_line = math.max(entry.lnum - 80, 1)
      local last_line = entry.lnum + 80
      local range = ("%d,%dp"):format(first_line, last_line)
      local command = ("sed -n %s -- %s"):format(vim.fn.shellescape(range), vim.fn.shellescape(entry.filename))

      self.state.remote_preview_job = vim.system(remote_command(remote, command), { text = true }, function(result)
        vim.schedule(function()
          if not self.state or self.state.remote_preview_generation ~= generation then
            return
          end

          local bufnr = self.state.bufnr
          if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end

          local output = result.stdout or ""
          local lines = vim.split(output, "\n", { plain = true })
          if lines[#lines] == "" then
            table.remove(lines)
          end
          if result.code ~= 0 and #lines == 0 then
            local error_text = result.stderr or ""
            lines = { error_text ~= "" and error_text or "Unable to load remote preview" }
          end
          if #lines == 0 then
            lines = { "" }
          end

          vim.bo[bufnr].modifiable = true
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
          vim.api.nvim_buf_clear_namespace(bufnr, preview_namespace, 0, -1)
          vim.bo[bufnr].filetype = vim.filetype.match({ filename = entry.filename }) or ""
          vim.bo[bufnr].modifiable = false

          local winid = self.state.winid
          if winid and vim.api.nvim_win_is_valid(winid) then
            local row = math.min(math.max(entry.lnum - first_line + 1, 1), #lines)
            local column = math.min(math.max((entry.col or 1) - 1, 0), #lines[row])
            vim.api.nvim_win_set_cursor(winid, { row, column })
            vim.wo[winid].cursorline = true
          end
        end)
      end)
    end,
  })
end

function M.live_grep(session)
  local remote = require("async-remote-write.utils").parse_remote_path(session.url)
  if not remote then
    vim.notify("Unable to determine the active remote repository", vim.log.levels.ERROR)
    return
  end

  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local finders = require("telescope.finders")
  local make_entry = require("telescope.make_entry")
  local pickers = require("telescope.pickers")
  local sorters = require("telescope.sorters")

  local make_vimgrep_entry = make_entry.gen_from_vimgrep({ cwd = remote.path })
  local finder = finders.new_job(function(prompt)
    return git_grep_command(remote, prompt)
  end, function(line)
    local entry = make_vimgrep_entry(line)
    if entry then
      entry.remote_url = remote_url(remote, entry.filename)
    end
    return entry
  end)

  pickers
    .new({}, {
      prompt_title = ("Remote Live Grep — %s:%s"):format(remote.host, remote.path),
      finder = finder,
      previewer = remote_previewer(remote),
      sorter = sorters.highlighter_only({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          if not selection or not selection.remote_url then
            return
          end

          actions.close(prompt_bufnr)
          require("async-remote-write.operations").simple_open_remote_file(selection.remote_url, {
            line = math.max((selection.lnum or 1) - 1, 0),
            character = math.max((selection.col or 1) - 1, 0),
          })
          require("config.remote_tree_follow").reveal(selection.remote_url)
        end)
        map("i", "<C-Space>", actions.to_fuzzy_refine)
        return true
      end,
      push_cursor_on_edit = true,
    })
    :find()
end

M.remote_url = remote_url
M.remote_command = remote_command
M.remote_previewer = remote_previewer

return M
