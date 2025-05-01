{ config, pkgs, lib, ... }:

{
  # Home Manager configuration for user "ask"
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Basic information about the user
  home.username = "ask";
  home.homeDirectory = "/home/ask";
  
  # Install packages specific to this user
  home.packages = with pkgs; [
    # Development tools
    git
    git-lfs
    ripgrep
    fd
    jq
    
    # Neovim with LunarVim setup
    neovim
    python3
    nodejs
    tree-sitter
    
    # Additional user tools
    tmux
    htop
    bat  # Better cat
    exa  # Better ls
    fzf  # Fuzzy finder
  ];
  
  # ZSH configuration (to match system shell)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    
    shellAliases = {
      ll = "ls -la";
      update = "sudo nixos-rebuild switch --flake /etc/nixos#cirrus";
    };
    
    initExtra = ''
      # Check if LunarVim needs to be installed
      if [ ! -d "$HOME/.local/share/lunarvim" ]; then
        echo "LunarVim not detected. Installing now..."
        
        # Create required directories
        mkdir -p $HOME/.local/share
        
        # Install LunarVim
        bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh) --no-install-dependencies
        
        echo "LunarVim installation complete!"
      fi
      
      # Add LunarVim to path
      if [ -d "$HOME/.local/bin" ]; then
        export PATH="$HOME/.local/bin:$PATH"
      fi
    '';
    
    # Customize prompt with git info
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "tmux" ];
      theme = "robbyrussell";
    };
  };
  
  # Neovim configuration (base for LunarVim)
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
  };
  
  # Git configuration
  programs.git = {
    enable = true;
    userName = "askasp";
    userEmail = "aksel@stadler.no";
  };
  
  # Terminal multiplexer configuration
  programs.tmux = {
    enable = true;
    shortcut = "a";
    terminal = "screen-256color";
    historyLimit = 10000;
  };
  
  # This makes home-manager create symlinks automatically
  home.stateVersion = "23.11";
} 