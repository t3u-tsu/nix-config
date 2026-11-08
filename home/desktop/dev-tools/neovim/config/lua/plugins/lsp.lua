-- lua/plugins/lsp.lua

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lspconfig = require("lspconfig")

    -- LSP がバッファにアタッチされたときのキーバインド設定
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = "LSP: " .. desc })
        end

        map("gd", vim.lsp.buf.definition, "Goto definition")
        map("gD", vim.lsp.buf.declaration, "Goto declaration")
        map("gi", vim.lsp.buf.implementation, "Goto implementation")
        map("gr", vim.lsp.buf.references, "Goto references")
        map("K", vim.lsp.buf.hover, "Hover documentation")
        map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("<leader>cf", function()
          vim.lsp.buf.format({ async = true })
        end, "Format buffer")
        map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
        map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
        map("]d", vim.diagnostic.goto_next, "Next diagnostic")
      end,
    })

    -- 保存時の自動フォーマット (Nix, Lua)
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.nix", "*.lua" },
      callback = function()
        vim.lsp.buf.format({ timeout_ms = 2000 })
      end,
    })

    -- サーバー設定 (PATH に存在する場合のみ起動)
    local servers = {
      nil_ls = {
        cmd = "nil",
        opts = {
          settings = {
            ["nil"] = {
              formatting = {
                command = { "nixfmt" },
              },
            },
          },
        },
      },
      lua_ls = {
        cmd = "lua-language-server",
        opts = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.env.VIMRUNTIME,
                },
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },
      },
      bashls = {
        cmd = "bash-language-server",
        opts = {},
      },
      perlnavigator = {
        cmd = "perlnavigator",
        opts = {},
      },
    }

    for name, srv in pairs(servers) do
      if vim.fn.executable(srv.cmd) == 1 then
        lspconfig[name].setup(srv.opts)
      end
    end
  end,
}
