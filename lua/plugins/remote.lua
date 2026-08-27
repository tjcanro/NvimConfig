return {
  {
    "inhesrom/remote-ssh.nvim",
    branch = "master",
    dependencies = {
      "inhesrom/telescope-remote-buffer",
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    cmd = {
      "RemoteSession",
      "RemoteSessionClose",
      "RemoteSessionPicker",
      "RemoteTreeBrowser",
      "RemoteOpen",
      "RemoteTerminalNew",
      "RemoteTerminalToggle",
      "RemoteGrep",
    },
    config = function()
      require("telescope-remote-buffer").setup()

      require("remote-ssh").setup({
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        filetype_to_server = {
          rust = "rust_analyzer",
        },
        async_write_opts = {
          autosave = false,
          save_debounce_ms = 250,
        },
        remote_terminal_opts = {
          window = { height = 0.20 },
          picker = { width = 22 },
        },
        remote_session_opts = {
          default_layout = {
            tree_browser_width_ratio = 0.20,
            terminal_height_ratio = 0.20,
          },
          terminal = {
            auto_create = true,
            start_in_session_path = true,
          },
        },
      })

      -- Match the local workspace layout: tree on the far left, editor on the
      -- upper right, and the remote terminal below the editor. The plugin
      -- opens its tree with a plain :vsplit, which otherwise puts it on the
      -- right and can leave it much wider than the configured ratio.
      local function find_remote_tree_window()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local name = vim.api.nvim_buf_get_name(buf)
          if name:find("Remote Tree:", 1, true) then
            return win
          end
        end
      end

      local function normalize_remote_layout()
        local tree_win = find_remote_tree_window()
        if not tree_win or not vim.api.nvim_win_is_valid(tree_win) then
          return
        end

        local terminal_manager = require("remote-terminal.terminal_manager")
        local terminal_win = terminal_manager.get_terminal_win()
        local picker_win = terminal_manager.get_picker_win()
        local editor_win

        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if win ~= tree_win and win ~= terminal_win and win ~= picker_win then
            editor_win = win
            break
          end
        end

        vim.api.nvim_set_current_win(tree_win)
        vim.cmd("wincmd H")
        vim.api.nvim_win_set_width(tree_win, math.max(30, math.floor(vim.o.columns * 0.20)))

        if editor_win and vim.api.nvim_win_is_valid(editor_win) then
          vim.api.nvim_set_current_win(editor_win)
        end
      end

      local session = require("remote-session.session")
      for _, method in ipairs({ "create", "restore" }) do
        local original = session[method]
        session[method] = function(...)
          local result = original(...)
          vim.defer_fn(normalize_remote_layout, 800)
          return result
        end
      end

      local terminal_windows = require("remote-terminal.window_manager")
      local original_create_split = terminal_windows.create_split
      terminal_windows.create_split = function(...)
        local result = original_create_split(...)
        vim.schedule(normalize_remote_layout)
        return result
      end

      -- The plugin's default cache warmer recursively opens many SSH
      -- connections. Large monorepos can trip server connection limits, so
      -- load directories only when they are expanded in the tree.
      require("async-remote-write.browse").get_cache_warming_status().config.auto_warm = false
      local tree_browser = require("async-remote-write.tree_browser")
      for index = 1, 20 do
        local name, load_initial_tree = debug.getupvalue(tree_browser.open_tree, index)
        if not name then
          break
        end
        if name == "load_initial_tree" then
          for child_index = 1, 20 do
            local child_name = debug.getupvalue(load_initial_tree, child_index)
            if not child_name then
              break
            end
            if child_name == "WARMING_MAX_DEPTH" then
              debug.setupvalue(load_initial_tree, child_index, 0)
              break
            end
          end
          break
        end
      end

      -- Poll open remote buffers frequently enough for remote agent edits to
      -- appear in Neovim while avoiding the recursive SSH connection storm
      -- caused by the cache warmer above.
      vim.api.nvim_create_autocmd("BufReadPost", {
        group = vim.api.nvim_create_augroup("RemoteFileWatcherTuning", { clear = true }),
        pattern = { "scp://*", "rsync://*" },
        callback = function(args)
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              require("async-remote-write").configure_watcher(args.buf, {
                poll_interval = 5000,
              })
            end
          end, 400)
        end,
      })

      -- Keep the remote tree expanded and selected to the file displayed in
      -- the editor, including files opened through Telescope and diff views.
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("RemoteTreeFollowCurrentFile", { clear = true }),
        pattern = { "scp://*", "rsync://*" },
        callback = function(args)
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              require("config.remote_tree_follow").reveal(args.buf)
            end
          end, 100)
        end,
      })
    end,
    keys = {
      { "<leader>Ro", "<cmd>RemoteSession<CR>", desc = "Open remote session" },
      { "<leader>Rp", "<cmd>RemoteSessionPicker<CR>", desc = "Pick remote session" },
      {
        "<leader>Rg",
        function()
          local session = require("remote-session.session_manager").get_active_session()
          if not session then
            vim.notify("No active remote session", vim.log.levels.WARN)
            return
          end
          require("config.remote_live_grep").live_grep(session)
        end,
        desc = "Live grep remote repository",
      },
      { "<leader>Rt", "<cmd>RemoteTerminalToggle<CR>", desc = "Toggle remote terminal" },
      { "<leader>Rx", "<cmd>RemoteSessionClose<CR>", desc = "Close remote session" },
    },
  },
}
