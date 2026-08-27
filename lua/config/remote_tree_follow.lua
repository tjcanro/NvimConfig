local M = {}

local reveal_generation = 0

local function upvalue(fn, wanted)
  for index = 1, 40 do
    local name, value = debug.getupvalue(fn, index)
    if not name then
      break
    end
    if name == wanted then
      return value
    end
  end
end

local function internals()
  local browser = require("async-remote-write.tree_browser")
  local load_initial_tree = upvalue(browser.open_tree, "load_initial_tree")
  if not load_initial_tree then
    return
  end

  return {
    state = upvalue(browser.open_tree, "TreeBrowser"),
    load_directory = upvalue(load_initial_tree, "load_directory"),
    create_item = upvalue(load_initial_tree, "create_tree_item"),
    refresh = upvalue(load_initial_tree, "refresh_display"),
  }
end

local function item_named(items, name)
  for _, item in ipairs(items or {}) do
    if item.name == name then
      return item
    end
  end
end

local function select_visible_item(state, target_path)
  for index, line in ipairs(state.line_data or {}) do
    local info = require("async-remote-write.utils").parse_remote_path(line.item.url)
    if info and info.path == target_path then
      if state.win_id and vim.api.nvim_win_is_valid(state.win_id) then
        vim.api.nvim_win_set_cursor(state.win_id, { index + (state.banner_offset or 0), 0 })
      end
      return true
    end
  end
  return false
end

local function reveal(target_url, token, attempt)
  if token ~= reveal_generation then
    return
  end

  local internal = internals()
  if
    not internal
    or not internal.state
    or not internal.load_directory
    or not internal.create_item
    or not internal.refresh
  then
    return
  end

  local state = internal.state
  local utils = require("async-remote-write.utils")
  local base = utils.parse_remote_path(state.base_url or "")
  local target = utils.parse_remote_path(target_url)
  if not base or not target or base.host ~= target.host then
    return
  end

  local root = base.path:gsub("/+$", "")
  if target.path ~= root and target.path:sub(1, #root + 1) ~= root .. "/" then
    return
  end

  local relative = target.path:sub(#root + 1):gsub("^/", "")
  local parts = vim.split(relative, "/", { plain = true, trimempty = true })
  if #parts == 0 then
    return
  end

  if not state.tree_data or #state.tree_data == 0 then
    if attempt < 12 then
      vim.defer_fn(function()
        reveal(target_url, token, attempt + 1)
      end, 200)
    end
    return
  end

  local function descend(items, part_index)
    if token ~= reveal_generation then
      return
    end

    local item = item_named(items, parts[part_index])
    if not item then
      return
    end

    if part_index == #parts then
      internal.refresh()
      vim.schedule(function()
        if token == reveal_generation then
          select_visible_item(state, target.path)
        end
      end)
      return
    end

    if not item.is_dir then
      return
    end

    state.expanded_dirs[item.url] = true
    if item.children then
      internal.refresh()
      descend(item.children, part_index + 1)
      return
    end

    internal.load_directory(item.url, function(files)
      if token ~= reveal_generation or not files then
        return
      end

      item.children = {}
      for _, file_info in ipairs(files) do
        table.insert(item.children, internal.create_item(file_info, item.depth + 1, item.url))
      end
      internal.refresh()
      descend(item.children, part_index + 1)
    end)
  end

  descend(state.tree_data, 1)
end

function M.reveal(target)
  local target_url = type(target) == "number" and vim.api.nvim_buf_get_name(target) or target
  if type(target_url) ~= "string" then
    return
  end
  if not target_url:match("^rsync://") and not target_url:match("^scp://") then
    return
  end

  reveal_generation = reveal_generation + 1
  reveal(target_url, reveal_generation, 1)
end

return M
