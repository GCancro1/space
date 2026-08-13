return {
  -- Love2D LSP configuration using native Neovim 0.11+ API
  -- Provides :LspInfo, :LspRestart, :LspLog commands
  {
    "neovim/nvim-lspconfig",
    config = function()
      print("[Love2D LSP] Config function running...")
      
      -- Detect Love2D API definitions (EmmyLua format)
      local love_api_path = nil
      local search_paths = {
        vim.fn.expand("~/.local/share/love-api/api"),
        vim.fn.expand("~/.local/share/love-api"),
        vim.fn.expand("~/love-api/api"),
        vim.fn.expand("~/love-api"),
        "/usr/local/share/love-api/api",
        "/usr/local/share/love-api",
        "/usr/share/love-api/api",
        "/usr/share/love-api",
      }
      
      for _, p in ipairs(search_paths) do
        if vim.fn.isdirectory(p) == 1 then
          love_api_path = p
          vim.notify("Love2D API found at: " .. p, vim.log.levels.INFO, { title = "Love2D LSP" })
          print("[Love2D LSP] Found at: " .. p)
          break
        else
          print("[Love2D LSP] Not at: " .. p)
        end
      end

      -- Build library table (no nil entries)
      local library = {
        vim.fn.stdpath("data") .. "/lazy/*/lua",
        "/usr/share/nvim/runtime/lua",
      }
      
      -- Add Love2D API if found
      if love_api_path then
        table.insert(library, love_api_path)
      end

      -- Configure lua_ls
      vim.lsp.config("lua_ls", {
        filetypes = { "lua" },
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim", "love" } },
            workspace = {
              library = library,
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })

      -- Enable lua_ls
      vim.lsp.enable("lua_ls")
      print("[Love2D LSP] lua_ls enabled with library: " .. vim.inspect(library))

      -- Add back :LspInfo, :LspRestart, :LspLog commands
      vim.api.nvim_create_user_command("LspInfo", function()
        vim.cmd("checkhealth lsp")
      end, { desc = "Show LSP health/info" })

      vim.api.nvim_create_user_command("LspRestart", function(opts)
        local name = opts.args ~= "" and opts.args or "lua_ls"
        local clients = vim.lsp.get_clients({ name = name })
        if #clients > 0 then
          for _, client in ipairs(clients) do
            vim.lsp.stop_client(client.id, true)
          end
          vim.defer_fn(function()
            vim.lsp.enable(name)
          end, 100)
          print("Restarted LSP: " .. name)
        else
          print("No LSP client found: " .. name)
        end
      end, { nargs = "?", desc = "Restart LSP client (default: lua_ls)" })

      vim.api.nvim_create_user_command("LspLog", function()
        print("LSP log: " .. vim.lsp.get_log_path())
        vim.cmd("tabnew " .. vim.lsp.get_log_path())
      end, { desc = "Open LSP log file" })

      -- Notify Love2D API status
      vim.schedule(function()
        if love_api_path then
          vim.notify(
            "Love2D API loaded from: " .. love_api_path,
            vim.log.levels.INFO,
            { title = "Love2D LSP" }
          )
        else
          vim.notify(
            "Love2D API definitions not found. For full Love2D completions:\n"
            .. "  git clone https://github.com/EmmyLua/Emmy-love-api ~/.local/share/love-api\n"
            .. "Then run :LspRestart lua_ls",
            vim.log.levels.WARN,
            { title = "Love2D LSP" }
          )
        end
      end)
    end,
  },
}