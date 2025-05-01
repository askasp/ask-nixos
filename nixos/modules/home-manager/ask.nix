{ config, pkgs, lib, ... }:

let
  # Updated aider script that safely accesses the API key
  aider = pkgs.writeShellScriptBin "aider" ''
    # Check if the secret file exists and is readable
    SECRET_PATH="/run/agenix/anthropic-api-key"
    
    if [ -r "$SECRET_PATH" ]; then
      # Read API key from the agenix-decrypted secret
      ANTHROPIC_API_KEY=$(cat "$SECRET_PATH")
      export ANTHROPIC_API_KEY
      
      # Run aider with the API key
      ${pkgs.python3Packages.aider-chat}/bin/aider --model claude-3-sonnet-20240229 "$@"
    else
      echo "Error: Anthropic API key not found at $SECRET_PATH"
      echo "Please make sure agenix is properly set up and the secret is decrypted."
      echo ""
      echo "You can still run aider with a manually provided API key:"
      echo "ANTHROPIC_API_KEY=your_key_here aider --model claude-3-sonnet-20240229"
      exit 1
    fi
  '';
in
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
    tmuxinator
    lazygit
    yazi  # Terminal file manager (for tmux binding)
    htop
    fzf  # Fuzzy finder
    
    # Custom aider script
    aider
    
    # Python packages
    python3Packages.aider-chat
  ];
  
  # Use external tmuxinator config files
  xdg.configFile = {
    # Add tmuxinator configs from the external files
    "tmuxinator/amino-api.yml".source = ./ask/tmuxinator/amino-api.yml;
    
    # Additional tmuxinator configs can be added here
    # "tmuxinator/another-project.yml".source = ./ask/tmuxinator/another-project.yml;
  };
  
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
    mouse = true;
    
    # Custom tmux configuration (Linux version)
    extraConfig = ''
      set -g prefix C-a
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind g display-popup -w90% -h90% -d "#{pane_current_path}" -E lazygit
      bind-key t display-popup -w90% -h90% -d "#{pane_current_path}" -E fish
      bind-key r display-popup -w90% -h90% -d "#{pane_current_path}" -E yazi

      unbind C-c

      # Use xclip for Linux copy
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel "xclip -selection clipboard"

      set -g xterm-keys on
      set -s escape-time 0
      setw -g mode-keys vi

      # Project shells
      # Enter project selector with prefix + a
      bind-key a switch-client -T project \; display-message "Project selector: f = frontend, p = api, c = cqrs, n = nixos, d= amino_dev, s=ask_server, m=mono, a=aichat"

      bind -T project f run-shell 'tmuxinator start amino-frontend'
      bind -T project p run-shell 'tmuxinator start amino-api'
      bind -T project c run-shell 'tmuxinator start ask-cqrs'
      bind -T project n run-shell 'tmuxinator start amino_nixos'
      bind -T project d run-shell 'tmuxinator start amino_dev'
      bind -T project s run-shell 'tmuxinator start ask-server'
      bind -T project m run-shell 'tmuxinator start mono'
      bind -T project a run-shell 'tmuxinator start aichat'
    '';
    
    plugins = [
      {
        plugin = pkgs.tmuxPlugins.sensible;
        extraConfig = "set -g @plugin 'tmux-plugins/tmux-sensible'";
      }
      {
        plugin = pkgs.tmuxPlugins.extrakto;
        extraConfig = "set -g @plugin 'laktak/extrakto'";
      }
      {
        plugin = pkgs.tmuxPlugins.resurrect;
        extraConfig = "set -g @plugin 'tmux-plugins/tmux-resurrect'";
      }
    ];
  };
  
  # This makes home-manager create symlinks automatically
  home.stateVersion = "23.11";
} 