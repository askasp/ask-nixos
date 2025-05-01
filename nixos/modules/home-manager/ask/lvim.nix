{pkgs, config, lib, ...}:

{
  programs.lvim = {
    enable = true;
    settings = {
      colorscheme = "neobones";
      relativenumber = true;
      log.level = "warn";
      format_on_save.enabled = true;
      
      # Prevent Mason from installing rust-analyzer
      lsp.installer.setup.ensure_installed = []; # Disable automatic installation
      
      # rust-analyzer configuration
      autocommands = [{
        event = "VimEnter"; # When Vim starts
        pattern = "*";
        callback = ''
          function()
            # Create symlink from Mason's rust-analyzer to system one if needed
            local mason_bin_dir = vim.fn.expand("~/.local/share/lvim/mason/bin")
            local system_rust_analyzer = vim.fn.expand("${pkgs.rust-analyzer}/bin/rust-analyzer")
            local mason_rust_analyzer = mason_bin_dir .. "/rust-analyzer"
            
            # Check if system rust-analyzer exists
            if vim.fn.executable(system_rust_analyzer) == 1 then
              # Create mason bin dir if it doesn't exist
              vim.fn.system("mkdir -p " .. mason_bin_dir)
              
              # Remove existing file/symlink if it exists
              vim.fn.system("rm -f " .. mason_rust_analyzer)
              
              # Create symlink
              vim.fn.system("ln -sf " .. system_rust_analyzer .. " " .. mason_rust_analyzer)
            end
          end
        '';
      }];

      # Skip Mason's rust-analyzer and use system one directly
      lsp.automatic_configuration.skipped_servers = ["rust_analyzer"];
      
      plugins = [
        {
          name = "mcchrish/zenbones.nvim";
          dependencies = [ "rktjmp/lush.nvim" ];
          priority = 1000;
        }
        {
          name = "zbirenbaum/copilot.lua";
          cmd = [ "Copilot" ];
          event = "InsertEnter";
          config = ''
            require("copilot").setup({})
          '';
        }
        {
          name = "zbirenbaum/copilot-cmp";
          config = ''
            require("copilot_cmp").setup({
              suggestion = { enabled = false },
              panel = { enabled = false }
            })
          '';
        }
      ];
      
      # Additional custom LunarVim settings can be added here
    };
    
    # Manual setup of rust-analyzer is done via extraConfig
    extraConfig = ''
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
    '';
  };
} 