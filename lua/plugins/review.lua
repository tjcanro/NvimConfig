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
      { "<leader>go", "<cmd>DiffviewOpen<CR>", desc = "Open Git diff" },
      { "<leader>gc", "<cmd>DiffviewClose<CR>", desc = "Close Git diff" },
      { "<leader>gf", "<cmd>DiffviewFocusFiles<CR>", desc = "Focus changed files" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "Current file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Repository history" },
    },
  },
}
