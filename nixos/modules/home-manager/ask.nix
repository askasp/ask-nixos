{ config, pkgs, lib, ... }:

{
  # Home Manager configuration for user "ask"
  
  # Remove nixpkgs.config since we use global packages
  # nixpkgs.config.allowUnfree = true;
  
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
    
    # Additional dependencies for LunarVim
    # Don't include neovim itself to avoid collisions
    python3
    nodejs
    tree-sitter
    
    # Additional user tools
    tmux
    htop
    fzf  # Fuzzy finder
  ];
  
  # ZSH configuration (to match system shell)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    
    # Updated option names
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    
    shellAliases = {
      ll = "ls -la";
      update = "sudo nixos-rebuild switch --flake /etc/nixos#cirrus";
    };
    
    # Updated to initContent
    initContent = ''
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
  
  # Let system manage neovim to avoid collisions
  programs.neovim.enable = false;
  
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