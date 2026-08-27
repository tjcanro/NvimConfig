local M = {}

function M.find_files(session)
  local remote = require("async-remote-write.utils").parse_remote_path(session.url)
  if not remote then
    vim.notify("Unable to determine the active remote repository", vim.log.levels.ERROR)
    return
  end

  local picker_helpers = require("config.remote_live_grep")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local finders = require("telescope.finders")
  local pickers = require("telescope.pickers")

  local command = picker_helpers.remote_command(remote, "git ls-files --cached --others --exclude-standard")
  local finder = finders.new_oneshot_job(command, {
    entry_maker = function(line)
      return {
        value = line,
        display = line,
        ordinal = line,
        filename = line,
        lnum = 1,
        remote_url = picker_helpers.remote_url(remote, line),
      }
    end,
  })

  pickers
    .new({}, {
      prompt_title = ("Remote Find Files — %s:%s"):format(remote.host, remote.path),
      finder = finder,
      previewer = picker_helpers.remote_previewer(remote),
      sorter = conf.file_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          if not selection or not selection.remote_url then
            return
          end

          actions.close(prompt_bufnr)
          require("async-remote-write.operations").simple_open_remote_file(selection.remote_url)
          require("config.remote_tree_follow").reveal(selection.remote_url)
        end)
        return true
      end,
    })
    :find()
end

return M
