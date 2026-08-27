return {
  {
    "dlyongemallo/diffview-plus.nvim",
    version = "*",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      enhanced_diff_hl = true,
      file_panel = {
        listing_style = "tree",
        win_config = { position = "left", width = 35 },
      },
      keymaps = {
        view = {
          {
            "n",
            "]c",
            function()
              vim.cmd("normal! ]c")
            end,
            { desc = "Next diff hunk" },
          },
          {
            "n",
            "[c",
            function()
              vim.cmd("normal! [c")
            end,
            { desc = "Previous diff hunk" },
          },
        },
      },
    },
    keys = {
      {
        "<leader>go",
        function()
          local ok, session_manager = pcall(require, "remote-session.session_manager")
          local session = ok and session_manager.get_active_session() or nil
          if session then
            require("config.remote_git_diff").open(session)
          else
            vim.cmd("DiffviewOpen")
          end
        end,
        desc = "Open local or remote Git diff",
      },
      {
        "<leader>gc",
        function()
          if not require("config.remote_git_diff").close() then
            vim.cmd("DiffviewClose")
          end
        end,
        desc = "Close local or remote Git diff",
      },
      { "<leader>gf", "<cmd>DiffviewFocusFiles<CR>", desc = "Focus changed files" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "Current file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Repository history" },
    },
  },
}
