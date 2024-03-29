-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

require("tabnine").setup({
  disable_auto_comment = true,
  accept_keymap = "<C-o>", -- "<TAB>"
  dismiss_keymap = "<C-]>",
  debounce_ms = 800,
  suggestion_color = { gui = "#808080", cterm = 244 },
  exclude_filetypes = { "TelescopePrompt" },
  log_file_path = nil, -- absolute path to Tabnine log file
})

require("nvim-treesitter.configs").setup({
  autotag = {
    enable = true,
  },
})

local null_ls = require("null-ls")
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

-- TODO: figure out how to wire up ember-template-lint
local lsp_formatting = function(buffer)
  vim.lsp.buf.format({
    filter = function(client)
      -- By default, ignore any formatters provider by other LSPs
      -- (such as those managed via lspconfig or mason)
      -- Also "eslint as a formatter" doesn't work :(
      return client.name == "null-ls"
    end,
    bufnr = buffer,
  })
end

local on_attach = function(client, buffer)
  -- the Buffer will be null in buffers like nvim-tree or new unsaved files
  if not buffer then
    return
  end

  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_clear_autocmds({ group = augroup, buffer = buffer })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup,
      buffer = buffer,
      callback = function()
        lsp_formatting(buffer)
      end,
    })
  end
end

null_ls.setup({
  sources = {
    -- Prettier, but faster (daemonized)
    null_ls.builtins.formatting.prettierd.with({
      filetypes = {
        "css",
        "json",
        "scss",
      },
    }),

    -- Code actions for staging hunks, blame, etc
    null_ls.builtins.code_actions.gitsigns,
    null_ls.builtins.completion.luasnip,

    -- Spell check that has better tooling
    -- all stored locally
    -- https://github.com/streetsidesoftware/cspell
    null_ls.builtins.diagnostics.cspell.with({
      -- This file is symlinked from my dotfiles repo
      extra_args = { "--config", "~/.cspell.json" },
    }),
    null_ls.builtins.code_actions.cspell.with({
      -- This file is symlinked from my dotfiles repo
      extra_args = { "--config", "~/.cspell.json" },
    }),
    -- null_ls.builtins.completion.spell,
  },
  on_attach = on_attach,
})

vim.wo.relativenumber = false
