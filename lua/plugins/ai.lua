local function active_remote_session()
  local ok, session_manager = pcall(require, "remote-session.session_manager")
  return ok and session_manager.get_active_session() or nil
end

local function active_remote_agent()
  local session = active_remote_session()
  return session and session.host == "colossus-dev" and "nico_claude" or nil
end

local selected_agent
local selected_session_id

local function sidekick_opts()
  local name = selected_agent or active_remote_agent()
  return name and { name = name } or nil
end

local function shell_join(args)
  return table.concat(
    vim.tbl_map(function(arg)
      return vim.fn.shellescape(arg)
    end, args),
    " "
  )
end

local function spawn_new_claude()
  local remote_session = active_remote_session()
  local cwd = vim.fs.root(0, ".git") or vim.fn.getcwd()
  local base_name = "claude"
  local command = { "claude" }
  local token = ("%05x"):format(vim.uv.hrtime() % 0x100000)
  local tool_name = "claude-" .. token

  if remote_session then
    if remote_session.host ~= "colossus-dev" then
      vim.notify("New remote Claude sessions are currently configured only for colossus-dev", vim.log.levels.WARN)
      return
    end

    local remote = require("async-remote-write.utils").parse_remote_path(remote_session.url)
    if not remote then
      vim.notify("Unable to determine the active remote repository", vim.log.levels.ERROR)
      return
    end

    base_name = "nico_claude"
    tool_name = "nico-" .. token
    local tmux_session = "nico-claude-" .. os.date("%Y%m%d-%H%M%S") .. "-" .. token
    local remote_command = shell_join({
      "tmux",
      "new-session",
      "-A",
      "-s",
      tmux_session,
      "-c",
      remote.path,
      [[bash -lc "exec claude"]],
    })

    command = { "ssh", "-tt", remote.host, remote_command }
    cwd = vim.fn.getcwd()
  end

  -- Give Sidekick a unique tool identity so it creates another tmux-backed
  -- session instead of resolving the canonical tool-and-directory session.
  local tool = require("sidekick.config").get_tool(base_name):clone({
    name = tool_name,
    cmd = command,
  })
  local Session = require("sidekick.cli.session")
  Session.setup()
  local session = Session.new({ tool = tool, cwd = cwd })

  -- Keep a single agent side panel visible while retaining hidden sessions in
  -- the picker. This affects only Sidekick terminals, not the bottom shell.
  for _, terminal in pairs(require("sidekick.cli.terminal").terminals) do
    terminal:hide()
  end

  local state = require("sidekick.cli.state").attach({
    tool = tool,
    session = session,
    installed = true,
  }, { show = true, focus = true })
  selected_agent = tool_name
  selected_session_id = state.session.id
end

return {
  "folke/sidekick.nvim",
  lazy = false,
  opts = {
    -- CLI integration does not require a Copilot subscription. Enable NES later
    -- if copilot-language-server is installed and authenticated.
    nes = { enabled = false },
    cli = {
      mux = { enabled = true, backend = "tmux" },
      tools = {
        claude = {},
        codex = {},
        nico_claude = {
          cmd = {
            "ssh",
            "-tt",
            "colossus-dev",
            [[tmux new-session -A -s nico-agent -c /home/tcanro/sim-pods 'bash -lc "exec claude --continue --agent simulation-helper --add-dir /home/tcanro/infra-controller-dev --name nico-simulation-agent"']],
          },
          is_proc = function(_, proc)
            return proc.cmd:find("ssh", 1, true) ~= nil
              and proc.cmd:find("colossus-dev", 1, true) ~= nil
              and (proc.cmd:find("nico-agent", 1, true) ~= nil or proc.cmd:find("nico-claude-", 1, true) ~= nil)
          end,
          url = "https://github.com/anthropics/claude-code",
          format = function(text)
            local Text = require("sidekick.text")
            Text.transform(text, function(path)
              local remote_path = path:match("^rsync:/+colossus%-dev/+(.+)$")
              return remote_path and ("/" .. remote_path) or path
            end, "SidekickLocFile")

            -- Reuse Claude's quoting and #Lx-Ly location formatting after
            -- converting the virtual rsync URL into a real remote path.
            return require("sidekick.config").get_tool("claude"):format(text)
          end,
        },
      },
    },
  },
  config = function(_, opts)
    require("sidekick").setup(opts)

    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("SidekickSpawnedAgents", { clear = true }),
      pattern = "SidekickCliDetach",
      callback = function(args)
        if args.data and args.data.id == selected_session_id then
          selected_agent = nil
          selected_session_id = nil
        end
      end,
    })

    -- Sidekick normally ignores virtual rsync buffers because they are not
    -- readable through the local filesystem. They are valid file context for
    -- the remote Claude tool, so allow its location renderer to include them.
    local location = require("sidekick.cli.context.location")
    local local_is_file = location.is_file
    location.is_file = function(buf)
      local name = vim.api.nvim_buf_get_name(buf)
      return name:match("^rsync:/+colossus%-dev/") ~= nil or local_is_file(buf)
    end
  end,
  keys = {
    {
      "<C-.>",
      function()
        require("sidekick.cli").focus(sidekick_opts())
      end,
      mode = { "n", "t", "i", "x" },
      desc = "Focus AI CLI",
    },
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle(sidekick_opts())
      end,
      desc = "Toggle AI CLI",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select({
          filter = { installed = true },
          cb = function(state)
            if state then
              local attached = require("sidekick.cli.state").attach(state, { show = true, focus = true })
              selected_agent = attached.tool.name
              selected_session_id = attached.session.id
            end
          end,
        })
      end,
      desc = "Select AI CLI",
    },
    {
      "<leader>an",
      spawn_new_claude,
      desc = "New Claude session",
    },
    {
      "<leader>ap",
      function()
        require("sidekick.cli").prompt(function(_, text)
          if text then
            require("sidekick.cli").send(vim.tbl_extend("force", sidekick_opts() or {}, { text = text }))
          end
        end)
      end,
      mode = { "n", "x" },
      desc = "Prompt AI with context",
    },
    {
      "<leader>at",
      function()
        require("sidekick.cli").send(vim.tbl_extend("force", sidekick_opts() or {}, { msg = "{this}" }))
      end,
      mode = { "n", "x" },
      desc = "Send current context to AI",
    },
    {
      "<leader>ad",
      function()
        require("sidekick.cli").close(sidekick_opts())
      end,
      desc = "Detach AI CLI session",
    },
  },
}
