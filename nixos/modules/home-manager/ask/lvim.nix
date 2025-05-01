{pkgs, config, lib, ...}:

{
  # Enable Neovim since LunarVim runs on top of it
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    
    # Install the plugins needed for zenbones/neobones colorscheme
    plugins = with pkgs.vimPlugins; [
      lush-nvim
      zenbones-nvim
      # Essential plugins that might be needed
      nvim-treesitter
      nvim-lspconfig
      plenary-nvim
      telescope-nvim
    ];
    
    # Install all the language dependencies we need
    extraPackages = with pkgs; [
      # LSP servers
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted # html, css, json, eslint
      nodePackages."@tailwindcss/language-server"
      lua-language-server
      pyright
      rust-analyzer
      
      # Formatters and linters
      nodePackages.prettier
      stylua
      black
      
      # Tools needed for telescope and other plugins
      ripgrep
      fd
    ];
  };
  
  # Create LunarVim configuration file directly
  xdg.configFile."lvim/config.lua".text = ''
    -- LunarVim base configuration
    lvim.log.level = "warn"
    lvim.format_on_save.enabled = true
    lvim.colorscheme = "neobones"
    vim.wo.relativenumber = true
    
    -- Ensure tree-sitter is enabled and configured
    lvim.builtin.treesitter.ensure_installed = {
      "bash", "c", "cpp", "javascript", "json", "lua", "python", "typescript",
      "tsx", "css", "rust", "java", "yaml", "markdown", "markdown_inline"
    }
    lvim.builtin.treesitter.highlight.enabled = true
    
    -- Configure LSP
    lvim.lsp.installer.setup.automatic_installation = false
    
    -- Prevent Mason from installing rust-analyzer
    lvim.lsp.installer.setup.ensure_installed = {} -- Disable automatic installation
    
    -- Skip Mason's rust-analyzer and use system one directly
    vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "rust_analyzer" })
    
    -- Add custom commands to run before LunarVim starts
    lvim.autocommands = {
      {
        "VimEnter", -- When Vim starts
        {
          pattern = "*",
          callback = function()
            -- Create symlink from Mason's rust-analyzer to system one if needed
            local mason_bin_dir = vim.fn.expand("~/.local/share/lvim/mason/bin")
            local system_rust_analyzer = vim.fn.expand("${pkgs.rust-analyzer}/bin/rust-analyzer")
            local mason_rust_analyzer = mason_bin_dir .. "/rust-analyzer"
            
            -- Check if system rust-analyzer exists
            if vim.fn.executable(system_rust_analyzer) == 1 then
              -- Create mason bin dir if it doesn't exist
              vim.fn.system("mkdir -p " .. mason_bin_dir)
              
              -- Remove existing file/symlink if it exists
              vim.fn.system("rm -f " .. mason_rust_analyzer)
              
              -- Create symlink
              vim.fn.system("ln -sf " .. system_rust_analyzer .. " " .. mason_rust_analyzer)
            end
          end,
        }
      }
    }
    
    -- Manual setup of rust-analyzer
    local system_analyzer_path = "${pkgs.rust-analyzer}/bin/rust-analyzer"
    
    require("lvim.lsp.manager").setup("rust_analyzer", {
      cmd = { system_analyzer_path },
      settings = {
        ["rust-analyzer"] = {
          checkOnSave = {
            command = "clippy",
          },
        },
      },
    })
    
    -- Ensure other LSPs are properly configured
    -- These will use the system-installed servers from NixOS
    local lspconfig = require("lspconfig")
    
    -- TypeScript/JavaScript
    if vim.fn.executable("typescript-language-server") == 1 then
      lspconfig.tsserver.setup{}
    end
    
    -- Python
    if vim.fn.executable("pyright") == 1 then
      lspconfig.pyright.setup{}
    end
    
    -- Lua
    if vim.fn.executable("lua-language-server") == 1 then
      lspconfig.lua_ls.setup{
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim", "lvim" }
            }
          }
        }
      }
    end
    
    -- Make sure we handle formatting correctly
    local formatters = require "lvim.lsp.null-ls.formatters"
    formatters.setup {
      { command = "prettier", filetypes = { "javascript", "typescript", "css", "html", "json" } },
      { command = "stylua", filetypes = { "lua" } },
      { command = "black", filetypes = { "python" } },
    }
    
    -- Add zenbones and other plugins
    lvim.plugins = {
      {
        "mcchrish/zenbones.nvim",
        dependencies = "rktjmp/lush.nvim",
        priority = 1000, -- Load colorscheme early
      },
      {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        config = function()
          require("copilot").setup({})
        end,
      },
      {
        "zbirenbaum/copilot-cmp",
        config = function()
          require("copilot_cmp").setup({
            suggestion = { enabled = false },
            panel = { enabled = false }
          })
        end
      },
      -- Additional plugins for better LSP experience
      {
        "folke/trouble.nvim",
        cmd = "TroubleToggle",
      },
      {
        "folke/lsp-colors.nvim",
      },
    }
    
    -- Enhance status line with LSP info
    lvim.builtin.lualine.sections.lualine_c = {
      {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        symbols = { error = " ", warn = " ", info = " ", hint = " " },
      },
      { "filename", path = 1 },
      {
        function()
          local msg = "No LSP"
          local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
          local clients = vim.lsp.get_active_clients()
          if next(clients) == nil then return msg end
          
          local lsp_names = {}
          for _, client in ipairs(clients) do
            local filetypes = client.config.filetypes
            if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
              table.insert(lsp_names, client.name)
            end
          end
          
          return table.concat(lsp_names, ", ")
        end,
        icon = " LSP:",
      }
    }
  '';
  
  # Install LunarVim during Home Manager activation if not installed already
  home.activation.installLunarVim = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "$HOME/.local/share/lunarvim" ]; then
      echo "Installing LunarVim..."
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG $HOME/.local/share
      $DRY_RUN_CMD bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh) --no-install-dependencies
    fi
  '';
} 