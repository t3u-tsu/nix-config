-- lua/plugins/lsp.lua

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
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

    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.nix", "*.lua", "*.typ" },
      callback = function()
        vim.lsp.buf.format({ timeout_ms = 2000 })
      end,
    })

    local function julials_cmd()
      local base = vim.lsp.config["julials"] and vim.lsp.config["julials"].cmd
      if type(base) ~= "table" then
        return nil
      end
      local depot_env = vim.env.JULIA_DEPOT_PATH
      local first_depot = depot_env and depot_env ~= ""
        and vim.split(depot_env, vim.fn.has("win32") == 1 and ";" or ":")[1]
      local depot = (first_depot and first_depot ~= "") and first_depot or vim.fn.expand("~/.julia")
      local sysimage = vim.fs.joinpath(vim.fs.normalize(depot), "environments", "nvim-lspconfig", "languageserver.so")
      if not vim.uv.fs_stat(sysimage) then
        return nil
      end
      local cmd = vim.deepcopy(base)
      table.insert(cmd, 2, "--sysimage=" .. sysimage)
      return cmd
    end

    -- Use Neovim 0.11+ native vim.lsp.config / vim.lsp.enable API
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
      julials = {
        cmd = "julia",
        opts = function()
          return {
            cmd = julials_cmd(),
            on_init = function(client)
              client.server_capabilities.semanticTokensProvider = nil
            end,
          }
        end,
      },
      tinymist = {
        cmd = "tinymist",
        opts = {
          settings = {
            exportPdf = "never",
            formatterMode = "typstyle",
          },
        },
      },
    }

    local has_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    local default_caps = has_cmp and cmp_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()

    local enabled = {}

    local function enable_server(name, srv)
      if enabled[name] or vim.fn.executable(srv.cmd) ~= 1 then
        return false
      end
      local raw_opts = type(srv.opts) == "function" and srv.opts() or (srv.opts or {})
      local opts = vim.tbl_deep_extend("force", { capabilities = default_caps }, raw_opts)
      vim.lsp.config(name, opts)
      vim.lsp.enable(name)
      enabled[name] = true
      return true
    end

    for name, srv in pairs(servers) do
      enable_server(name, srv)
    end

    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("UserJuliaLsp", { clear = true }),
      pattern = "DirenvLoaded",
      callback = function()
        if not enable_server("julials", servers.julials) then
          return
        end
        vim.notify("julials enabled", vim.log.levels.INFO)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "julia" then
            if #vim.lsp.get_clients({ bufnr = buf, name = "julials" }) == 0 then
              pcall(vim.api.nvim_exec_autocmds, "FileType", {
                group = "nvim.lsp.enable",
                buffer = buf,
              })
            end
          end
        end
      end,
    })
  end,
}
