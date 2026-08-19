return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 700 },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map("n", "]h", gs.next_hunk, "Next git hunk")
        map("n", "[h", gs.prev_hunk, "Previous git hunk")
        map({ "n", "x" }, "<leader>hs", gs.stage_hunk, "Stage hunk")
        map({ "n", "x" }, "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", gs.blame_line, "Blame line")
        map("n", "<leader>hd", gs.diffthis, "Diff against index")
      end,
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 300,
      spec = {
        { "<leader>a", group = "AI" },
        { "<leader>d", group = "Diagnostics" },
        { "<leader>e", group = "Explorer" },
        { "<leader>f", group = "Find / Format" },
        { "<leader>g", group = "Git review" },
        { "<leader>h", group = "Git hunks" },
        { "<leader>r", group = "Rename" },
        { "<leader>w", group = "Workspace / Write" },
      },
    },
  },
}
