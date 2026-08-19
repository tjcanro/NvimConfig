# Personal Neovim configuration

A focused Neovim 0.12 configuration for Rust, Go, infrastructure code, and
agent-assisted development. It uses `lazy.nvim` for plugins, native Neovim LSP
configuration, Mason for tool installation, and Sidekick for Codex/Claude CLI
sessions backed by tmux.

## Install

### Prerequisites

- Neovim 0.12 or newer
- Git, `make`, `curl`, `tar`, and a C compiler
- `ripgrep` for Telescope live grep
- `tree-sitter-cli` 0.26.1 or newer
- tmux for persistent AI CLI sessions
- A Nerd Font in the terminal for icons (optional but recommended)

On macOS with Homebrew:

```bash
brew install neovim ripgrep tree-sitter-cli tmux
brew install --cask font-jetbrains-mono-nerd-font
```

Clone and link the configuration:

```bash
git clone https://github.com/tjcanro/NvimConfig.git ~/Workspace/NvimConfig
ln -s ~/Workspace/NvimConfig ~/.config/nvim
nvim
```

If `~/.config/nvim` already exists, move it aside before creating the symlink.
The first launch installs plugins, parsers, language servers, and formatter
tools. Run `:checkhealth` after installation completes.

## Daily operations

The leader key is `Space`. Press leader and wait briefly to see available
groups in Which Key.

Run `neo-help` from a new shell to open this README in Neovim at any time.

### Files and search

| Operation | Mapping |
| --- | --- |
| Find files | `Ctrl-p` or `<leader>ff` |
| Search repository text | `<leader>fg` |
| Search repository for word under cursor | `<leader>fw` |
| Search selected Neo-tree directory | `<leader>fd` from Neo-tree |
| Search current buffer | `/` |
| Find open buffers | `<leader>fb` |
| Recent files | `<leader>fr` |
| Toggle file tree | `Ctrl-n` or `<leader>ee` |
| Show Git status tree | `<leader>eg` |
| Save | `<leader>w` |

### Neo-tree

The tmuxp development sessions start Neovim with Neo-tree open on the left.
Dotfiles, Git-ignored files, and other filtered entries are visible by default.

| Operation | Mapping |
| --- | --- |
| Toggle or focus Neo-tree | `Ctrl-n` or `<leader>ee` |
| Move selection | `j` / `k` |
| Open a file or expand a directory | `Enter` |
| Expand or collapse a directory | `Space` |
| Create a file | `a`, then enter its name |
| Create a directory | `A`, then enter its name |
| Rename | `r` |
| Move to another directory | `m`, then enter the destination |
| Delete | `d` |
| Make the selected directory the tree root | `.` |
| Move the tree root up one directory | `Backspace` |
| Find a directory | `D` |
| Search contents of selected directory | `<leader>fd` |
| Collapse the selected directory / all directories | `C` / `z` |
| Toggle hidden items manually | `H` |
| Show all Neo-tree mappings | `?` |

### Neovim windows and splits

Neovim calls each editor subdivision a **window**. These live inside a tmux
**pane**. `Ctrl-w` is a sequential prefix: press `Ctrl-w`, release it, and then
press the next key.

| Operation | Mapping or command |
| --- | --- |
| Split horizontally | `Ctrl-w`, `s` or `:split [file]` |
| Split vertically | `Ctrl-w`, `v` or `:vsplit [file]` |
| Create a new empty split | `Ctrl-w`, `n` |
| Move focus left/down/up/right | `Ctrl-w`, `h/j/k/l` |
| Move to next / previous window | `Ctrl-w`, `w` / `Ctrl-w`, `p` |
| Move current window to far left/down/up/right | `Ctrl-w`, `H/J/K/L` |
| Close current window | `Ctrl-w`, `c` |
| Close every other window | `Ctrl-w`, `o` |

Resize the currently focused Neovim window with:

| Operation | Mapping |
| --- | --- |
| Increase / decrease width | `Ctrl-w`, `>` / `Ctrl-w`, `<` |
| Increase / decrease height | `Ctrl-w`, `+` / `Ctrl-w`, `-` |
| Equalize all window sizes | `Ctrl-w`, `=` |
| Maximize width | `Ctrl-w`, vertical-bar key |
| Maximize height | `Ctrl-w`, `_` |

Prefix a resize command with a count to resize by more than one cell. For
example, `5`, `Ctrl-w`, `>` widens the current window by five columns.

### Bottom terminal

Press `<leader>~` (`Space`, then `Shift-backtick`) to open a reusable terminal
in a 10-row split at the bottom. Press the same mapping from either the editor
or terminal to hide it; reopening it preserves the running shell. The
`:BottomTerminalToggle` command provides the same operation.

| Operation | Mapping |
| --- | --- |
| Toggle bottom terminal | `<leader>~` |
| Leave terminal-input mode | `Esc`, `Esc` |
| Return to terminal-input mode | `i` |
| Move from terminal to editor above | `Esc`, `Esc`, then `Ctrl-w`, `k` |
| Close the terminal process | Type `exit` in the shell |

### tmux panes and windows

The tmux prefix is `Ctrl-Space`. It is also sequential: press and release the
prefix, then press the command key. Lowercase `h/j/k/l` changes pane focus;
uppercase `H/J/K/L` resizes the pane by five cells.

| Operation | Mapping |
| --- | --- |
| Move pane focus left/down/up/right | `Ctrl-Space`, `h/j/k/l` |
| Resize pane left/down/up/right | `Ctrl-Space`, `H/J/K/L` |
| Split pane left/right | `Ctrl-Space`, `%` |
| Split pane top/bottom | `Ctrl-Space`, `"` |
| Toggle pane zoom | `Ctrl-Space`, `z` |
| Close pane | `Ctrl-Space`, `x` |
| Create a tmux window | `Ctrl-Space`, `c` |
| Previous / next tmux window | `Ctrl-Space`, `p/n` |

The resize bindings are repeatable: after the first prefixed resize, continue
pressing `H/J/K/L` quickly without repeating `Ctrl-Space`. Mouse support is also
enabled, so pane borders can be dragged.

### Code intelligence

| Operation | Mapping |
| --- | --- |
| Go to definition / declaration | `gd` / `gD` |
| Find references / implementation | `gr` / `gi` |
| Hover documentation | `K` |
| Code action | `<leader>ca` |
| Rename symbol | `<leader>rn` |
| Document / workspace symbols | `<leader>ds` / `<leader>ws` |
| Previous / next diagnostic | `[d` / `]d` |
| Diagnostic details | `<leader>de` |
| Format buffer or selection | `<leader>fm` |

Completion uses `blink.cmp`. Use `Ctrl-n`/`Ctrl-p` to select, `Ctrl-y` to
accept, `Ctrl-space` to show documentation, and `Tab`/`Shift-Tab` to move
through snippets.

Formatting runs on save by default. Use `:FormatDisable` globally,
`:FormatDisable!` for only the current buffer, and `:FormatEnable` to turn it
back on. `:ConformInfo` shows the formatter selected for the current file.

### Git and syntax-aware movement

| Operation | Mapping |
| --- | --- |
| Previous / next hunk | `[h` / `]h` |
| Stage / reset hunk | `<leader>hs` / `<leader>hr` |
| Preview hunk | `<leader>hp` |
| Blame line | `<leader>hb` |
| Previous / next function | `[f` / `]f` |
| Previous / next class | `[c` / `]c` |
| Select function | `if` / `af` |
| Select class | `ic` / `ac` |
| Select parameter | `ip` / `ap` |

`nvim-surround` keeps its standard mappings: `ys` adds a surrounding pair,
`ds` deletes it, and `cs` changes it. `gcc` comments a line and `gc` comments a
motion or visual selection.

### Code review

Diffview provides a repository-wide review of every changed file. Gitsigns is
best for uncommitted hunks in the working tree; Diffview is best for the full
PR or MR range.

| Operation | Mapping or command |
| --- | --- |
| Open working-tree diff | `<leader>go` or `:DiffviewOpen` |
| Open a PR-style branch diff | `:DiffviewOpen origin/main...HEAD` |
| Close the review | `<leader>gc` or `:DiffviewClose` |
| Focus / toggle changed-file list | `<leader>gf` / `:DiffviewToggleFiles` |
| Current file / repository history | `<leader>gh` / `<leader>gH` |
| Next / previous changed file | `Tab` / `Shift-Tab` |
| Next / previous diff hunk | `]c` / `[c` |
| Show Diffview's contextual mappings | `g?` |

This workstation also installs two shell helpers:

```bash
review-pr 123
review-mr 456
```

Each helper creates or refreshes an isolated worktree under
`~/Workspace/reviews/`, fetches the PR or MR head and target branch, and opens a
reusable tmux session. Neovim starts with the exact `<base>...HEAD` Diffview and
the bottom terminal on the left; `claude --agent code-reviewer` starts on the
right. Running the same command again reuses the worktree and tmux session.

Run a helper from its repository, or pass a checkout explicitly:

```bash
review-pr 123 --repo ~/Workspace/infra-controller
review-mr 456 --repo ~/Workspace/rackmanagementservice
review-pr 123 --prepare-only
```

When no repository is supplied and the current directory is not an appropriate
checkout, `review-pr` defaults to `~/Workspace/infra-controller` and
`review-mr` defaults to `~/Workspace/rackmanagementservice`. Set
`CODE_REVIEW_ROOT` to change where review worktrees are stored.

The personal Claude reviewer is defined at
`~/.claude/agents/code-reviewer.md`. Start it manually from any checkout with:

```bash
claude --agent code-reviewer "Review origin/main...HEAD"
```

It is read-only: it can inspect the repository and run checks, but it does not
edit code or submit review decisions. Its output is severity-ordered findings
with exact file locations, trigger scenarios, checks run, and unresolved risks.

## Languages and tools

Mason installs and enables language servers for:

- Rust (`rust_analyzer`, configured to run Clippy)
- Go (`gopls`)
- C/C++ (`clangd`)
- Python (`basedpyright`, with Ruff formatting)
- Lua, Bash, JSON, YAML, TOML, and Markdown

SchemaStore supplies current JSON and YAML schemas, which is particularly
useful for Kubernetes, GitHub Actions, and common configuration files. Mason
also manages `stylua`, `ruff`, `shfmt`, `prettier`, and `goimports`. Rustfmt,
gofmt, and Terraform formatting use their normal toolchains when present.

Useful maintenance commands:

- `:Lazy` — inspect, update, or profile plugins
- `:Mason` — inspect language servers and tools
- `:MasonToolsInstallSync` — reconcile all configured external tools
- `:TSUpdate` — update Tree-sitter parsers after plugin updates
- `:checkhealth` — full environment diagnostic
- `:checkhealth vim.lsp` — enabled and attached language servers
- `:checkhealth sidekick` — available agent CLIs and multiplexer support

After intentional plugin updates, commit the resulting `lazy-lock.json` so the
same working plugin versions can be restored on another machine.

## AI agent integration

The default setup uses
[sidekick.nvim](https://github.com/folke/sidekick.nvim) because it preserves the
terminal-native Codex/Claude workflow and can keep CLI sessions alive in tmux.
It does not require an API key beyond the authentication already used by each
CLI.

| Operation | Mapping |
| --- | --- |
| Toggle current AI CLI | `<leader>aa` |
| Select an installed CLI | `<leader>as` |
| Prompt with editor context | `<leader>ap` |
| Send the current file or selection | `<leader>at` |
| Focus the agent terminal | `Ctrl-.` |
| Detach the agent session | `<leader>ad` |

Codex and Claude are enabled as choices. Run `codex login` or the equivalent
Claude login before first use. Sidekick's Next Edit Suggestions are disabled by
default because that feature requires GitHub Copilot; the CLI integration does
not.

For this workstation, the recommended workflow is still one editor pane plus a
dedicated agent pane in tmux. Sidekick is best for sending a precise selection,
file, or diagnostic without losing the persistent CLI session.

For durable agent context:

- Put repository rules and commands in `AGENTS.md`. Codex loads global and
  nested project instructions at session start.
- Put repeatable procedures in Codex skills rather than copying long prompts.
- Define specialist Codex agents under `~/.codex/agents/*.toml`; the CLI can
  spawn them as subagents, and `/agent` shows their threads.
- Keep active task state in a concise handoff file so a restarted CLI session
  can resume safely.

See the official OpenAI documentation for
[AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md),
[custom agents and subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents),
and [skills](https://learn.chatgpt.com/docs/build-skills).

If a fully embedded chat buffer is preferred later,
[CodeCompanion.nvim](https://github.com/olimorris/codecompanion.nvim) is the
stronger alternative: it supports Codex and Claude through CLI/ACP adapters,
editor context, MCP tools, and inline transformations. Avoid enabling both
Sidekick and CodeCompanion for the same workflow until the desired keymaps and
session ownership are clear.

## Layout and customization

Core settings live in `lua/config/`; plugin specifications live in
`lua/plugins/`. Add one plugin or one closely related plugin group per file.
Keep mappings near the feature that owns them and give every non-obvious mapping
a description so Which Key remains useful.

The color scheme is Tokyo Night and the status line uses Lualine. Configure the
terminal to use a Nerd Font if file icons render as squares.

## Troubleshooting

- No search results: confirm `rg --version` works.
- Missing icons: select the installed Nerd Font in the terminal profile.
- LSP does not attach: run `:checkhealth vim.lsp`, then check `:Mason` and the
  repository root markers.
- Parser error after updating: run `:TSUpdate`; the current Tree-sitter main
  branch requires Neovim 0.12 and `tree-sitter-cli` 0.26.1+.
- Formatter unavailable: run `:ConformInfo` and `:MasonToolsInstallSync`.
- Agent CLI missing: verify `codex --version` or `claude --version`, then run
  `:checkhealth sidekick`.
- Sidekick reports a missing Copilot LSP: expected in this setup because Next
  Edit Suggestions are disabled; Codex and Claude CLI support remains healthy.
