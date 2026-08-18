local parsers = {
  "bash",
  "c",
  "cmake",
  "comment",
  "cpp",
  "diff",
  "dockerfile",
  "git_config",
  "git_rebase",
  "gitattributes",
  "gitcommit",
  "gitignore",
  "go",
  "gomod",
  "gosum",
  "gotmpl",
  "gowork",
  "helm",
  "html",
  "json",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "proto",
  "python",
  "query",
  "regex",
  "ron",
  "rust",
  "terraform",
  "toml",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({})
      require("nvim-treesitter").install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("personal_treesitter", { clear = true }),
        callback = function(args)
          local language = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if language and vim.tbl_contains(parsers, language) then
            pcall(vim.treesitter.start, args.buf, language)
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      select = { lookahead = true },
      move = { set_jumps = true },
    },
    config = function(_, opts)
      require("nvim-treesitter-textobjects").setup(opts)

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local map = vim.keymap.set

      map({ "x", "o" }, "af", function()
        select.select_textobject("@function.outer", "textobjects")
      end, { desc = "Around function" })
      map({ "x", "o" }, "if", function()
        select.select_textobject("@function.inner", "textobjects")
      end, { desc = "Inside function" })
      map({ "x", "o" }, "ac", function()
        select.select_textobject("@class.outer", "textobjects")
      end, { desc = "Around class" })
      map({ "x", "o" }, "ic", function()
        select.select_textobject("@class.inner", "textobjects")
      end, { desc = "Inside class" })
      map({ "x", "o" }, "ap", function()
        select.select_textobject("@parameter.outer", "textobjects")
      end, { desc = "Around parameter" })
      map({ "x", "o" }, "ip", function()
        select.select_textobject("@parameter.inner", "textobjects")
      end, { desc = "Inside parameter" })

      map({ "n", "x", "o" }, "]f", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "Next function" })
      map({ "n", "x", "o" }, "[f", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "Previous function" })
      map({ "n", "x", "o" }, "]c", function()
        move.goto_next_start("@class.outer", "textobjects")
      end, { desc = "Next class" })
      map({ "n", "x", "o" }, "[c", function()
        move.goto_previous_start("@class.outer", "textobjects")
      end, { desc = "Previous class" })
    end,
  },
}
