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
    ];
  };
  
  # Create LunarVim configuration file directly
  xdg.configFile."lvim/config.lua".text = ''
    -- LunarVim base configuration
    lvim.log.level = "warn"
    lvim.format_on_save.enabled = true
    lvim.colorscheme = "neobones"
    vim.wo.relativenumber = true
    
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