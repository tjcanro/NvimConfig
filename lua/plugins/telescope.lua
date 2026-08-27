return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
    "nvim-telescope/telescope-ui-select.nvim",
  },
  cmd = "Telescope",
  opts = function()
    local actions = require("telescope.actions")
    return {
      defaults = {
        mappings = {
          i = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
          },
        },
        path_display = { "smart" },
      },
      extensions = {
        ["ui-select"] = require("telescope.themes").get_dropdown(),
      },
    }
  end,
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    pcall(telescope.load_extension, "fzf")
    telescope.load_extension("ui-select")
  end,
  keys = function()
    local builtin = require("telescope.builtin")
    local function find_files()
      local ok, session_manager = pcall(require, "remote-session.session_manager")
      local session = ok and session_manager.get_active_session() or nil
      if session then
        require("config.remote_find_files").find_files(session)
        return
      end

      builtin.find_files()
    end

    local function live_grep()
      local ok, session_manager = pcall(require, "remote-session.session_manager")
      local session = ok and session_manager.get_active_session() or nil
      if session then
        require("config.remote_live_grep").live_grep(session)
        return
      end

      builtin.live_grep()
    end

    return {
      { "<C-p>", find_files, desc = "Find files locally or remotely" },
      { "<leader>ff", find_files, desc = "Find files locally or remotely" },
      { "<leader>fg", live_grep, desc = "Live grep local or remote repository" },
      { "<leader>fw", builtin.grep_string, desc = "Find word under cursor" },
      { "<leader>fb", builtin.buffers, desc = "Find buffers" },
      { "<leader>fh", builtin.help_tags, desc = "Find help" },
      { "<leader>fr", builtin.oldfiles, desc = "Recent files" },
      { "<leader>fc", builtin.git_commits, desc = "Git commits" },
      { "<leader>fs", builtin.lsp_document_symbols, desc = "Document symbols" },
      {
        "/",
        function()
          builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
            winblend = 10,
            previewer = false,
          }))
        end,
        desc = "Search current buffer",
      },
    }
  end,
}
