local lsp_servers = {
  "basedpyright",
  "bashls",
  "clangd",
  "gopls",
  "jsonls",
  "lua_ls",
  "marksman",
  "rust_analyzer",
  "taplo",
  "yamlls",
}

return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 400 } },
      signature = { enabled = true },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
  },
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
    opts = { ui = { border = "rounded" } },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = {
        "basedpyright",
        "bash-language-server",
        "clangd",
        "goimports",
        "gopls",
        "lua-language-server",
        "marksman",
        "prettier",
        "ruff",
        "rust-analyzer",
        "shfmt",
        "stylua",
        "taplo",
        "json-lsp",
        "yaml-language-server",
      },
      run_on_start = true,
      start_delay = 1500,
      debounce_hours = 24,
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
      "saghen/blink.cmp",
      "b0o/SchemaStore.nvim",
    },
    opts = {
      ensure_installed = lsp_servers,
      automatic_enable = lsp_servers,
    },
    config = function(_, opts)
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { library = { vim.env.VIMRUNTIME } },
          },
        },
      })

      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            check = { command = "clippy" },
          },
        },
      })

      local schemastore = require("schemastore")
      vim.lsp.config("jsonls", {
        settings = { json = { schemas = schemastore.json.schemas(), validate = { enable = true } } },
      })
      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" },
            schemas = schemastore.yaml.schemas(),
          },
        },
      })

      require("mason-lspconfig").setup(opts)
    end,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      vim.diagnostic.config({
        severity_sort = true,
        float = { border = "rounded", source = "if_many" },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = true,
        virtual_text = { source = "if_many", spacing = 2 },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("personal_lsp_attach", { clear = true }),
        callback = function(event)
          local map = function(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gr", vim.lsp.buf.references, "Find references")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ds", vim.lsp.buf.document_symbol, "Document symbols")
          map("<leader>ws", vim.lsp.buf.workspace_symbol, "Workspace symbols")

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight = vim.api.nvim_create_augroup("personal_lsp_highlight_" .. event.buf, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = highlight,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = highlight,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },
}
