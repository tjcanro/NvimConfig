return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>fm",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = { "n", "x" },
      desc = "Format buffer or selection",
    },
  },
  opts = {
    notify_no_formatters = false,
    default_format_opts = { lsp_format = "fallback" },
    formatters_by_ft = {
      bash = { "shfmt" },
      go = { "goimports", "gofmt" },
      json = { "prettier", stop_after_first = true },
      jsonc = { "prettier", stop_after_first = true },
      lua = { "stylua" },
      markdown = { "prettier", stop_after_first = true },
      python = { "ruff_format" },
      rust = { "rustfmt", lsp_format = "fallback" },
      sh = { "shfmt" },
      terraform = { "terraform_fmt" },
      yaml = { "prettier", stop_after_first = true },
    },
    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 1000, lsp_format = "fallback" }
    end,
  },
  init = function()
    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        vim.b.disable_autoformat = true
      else
        vim.g.disable_autoformat = true
      end
    end, { bang = true, desc = "Disable autoformat globally (or buffer-local with !)" })

    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, { desc = "Enable autoformat" })
  end,
}
