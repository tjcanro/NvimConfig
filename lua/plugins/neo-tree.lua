return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = "Neotree",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    close_if_last_window = true,
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    window = { width = 36 },
  },
  keys = {
    { "<C-n>", "<cmd>Neotree toggle reveal filesystem left<CR>", desc = "Toggle file tree" },
    { "<leader>ee", "<cmd>Neotree toggle reveal filesystem left<CR>", desc = "Toggle file tree" },
    { "<leader>eg", "<cmd>Neotree git_status toggle<CR>", desc = "Git status tree" },
  },
}
