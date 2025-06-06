{ config, pkgs, lib, ... }:

let
  # Aider script using OpenRouter to access Anthropic models
  aider = pkgs.writeShellScriptBin "aider" ''
    # Check if the secret file exists and is readable
    SECRET_PATH="/run/agenix/openrouter-api-key"
    
    if [ -r "$SECRET_PATH" ]; then
      # Read API key from the agenix-decrypted secret
      OPENROUTER_API_KEY=$(cat "$SECRET_PATH")
      export OPENROUTER_API_KEY
      
      # Run aider with OpenRouter to access Claude
      ${pkgs.python3Packages.aider-chat}/bin/aider --openai-api-base "https://openrouter.ai/api/v1" --model "anthropic/claude-3-sonnet" "$@"
    else
      echo "Error: OpenRouter API key not found at $SECRET_PATH"
      echo "Please make sure agenix is properly set up and the secret is decrypted."
      echo ""
      echo "You can still run aider with a manually provided API key:"
      echo "OPENROUTER_API_KEY=your_key_here aider --openai-api-base \"https://openrouter.ai/api/v1\" --model \"anthropic/claude-3-sonnet\""
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
  
  # Import LunarVim configuration
  imports = [
    ./ask/lvim.nix
  ];
  
  # Install packages specific to this user
  home.packages = with pkgs; [
    # Development tools
    git
    git-lfs
    ripgrep
    fd
    jq
    
    # Additional dependencies for LunarVim
    python3
    nodejs
    tree-sitter
    gcc # Needed for TreeSitter compilation
    gnumake # Needed for plugin compilation
    unzip # Used by Mason for package extraction
    
    # LSP-related tools
    nodePackages.npm
    
    # Additional user tools
    tmux
    tmuxinator
    lazygit
    yazi  # Terminal file manager (for tmux binding)
    htop
    fzf  # Fuzzy finder
    
    # Custom aider script
    aider
  ];
  
  # Use external tmuxinator config files
  xdg.configFile = {
    # Add tmuxinator configs from the external files
    "tmuxinator/amino-api.yml".source = ./ask/tmuxinator/amino-api.yml;
    "tmuxinator/amino-frontend.yml".source = ./ask/tmuxinator/amino-frontend.yml;
    "tmuxinator/ask-nixos.yml".source = ./ask/tmuxinator/ask-nixos.yml;
    "tmuxinator/nixos.yml".source = ./ask/tmuxinator/nixos.yml;
    
    # LunarVim config removed and replaced with the imported module
    
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

      # Enhanced mouse support for SSH sessions
      set -g mouse on
      set -g terminal-overrides 'xterm*:smcup@:rmcup@'
      set -ag terminal-overrides ',*:Ss=\E[%p1%d q:Se=\E[2 q'
      set -ag terminal-overrides ',*:RGB'
      
      # Better scroll experience
      bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
      bind -n WheelDownPane select-pane -t= \; send-keys -M
      
      # Increase scrollback buffer size
      set -g history-limit 50000

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
      bind -T project n run-shell 'tmuxinator start nixos'
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
  
  # Home activation script to ensure all required directories exist
  home.activation = {
    createConfigDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG $HOME/.config/lvim
    '';
  };
  
  # This makes home-manager create symlinks automatically
  home.stateVersion = "23.11";
  
  # Set environment variables for development
  home.sessionVariables = {
    # For Rust/Cargo builds
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };
} 
