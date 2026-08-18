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
      },
    },
  },
  keys = {
    {
      "<C-.>",
      function()
        require("sidekick.cli").focus()
      end,
      mode = { "n", "t", "i", "x" },
      desc = "Focus AI CLI",
    },
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Toggle AI CLI",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select({ filter = { installed = true } })
      end,
      desc = "Select AI CLI",
    },
    {
      "<leader>ap",
      function()
        require("sidekick.cli").prompt()
      end,
      mode = { "n", "x" },
      desc = "Prompt AI with context",
    },
    {
      "<leader>at",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "n", "x" },
      desc = "Send current context to AI",
    },
    {
      "<leader>ad",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Detach AI CLI session",
    },
  },
}
