{ config, pkgs, ... }:

{
  # Common development tools
  environment.systemPackages = with pkgs; [
    # Version control
    git
    git-lfs
    
    # Terminal multiplexer
    tmux
    
    # Rust development
    rustup  # Rust toolchain manager
    cargo   # Rust package manager
    rustc   # Rust compiler
    rust-analyzer # LSP for Rust
    
    # Build essentials
    gcc
    gnumake
    cmake
    pkg-config
    
    # Editor dependencies for LunarVim
    neovim
    python3  # For some neovim plugins
    nodejs   # For some neovim plugins
    ripgrep  # Used by Telescope
    fd       # Used by Telescope
    
    # Other useful tools
    jq
    tree
    htop
    curl
    wget
  ];
  
  # Set up LunarVim for user (can be moved to a home-manager config)
  # This is a simplified installation approach; for a more complete setup, 
  # consider using home-manager to manage the config files
  system.activationScripts.installLunarVim = ''
    if [ ! -d /home/youruser/.local/share/lunarvim ]; then
      echo "Installing LunarVim..."
      export USER=youruser
      export HOME=/home/$USER
      mkdir -p $HOME/.local/share
      chown -R $USER:users $HOME/.local
      sudo -u $USER bash -c "curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh | bash -s -- --no-install-dependencies"
    fi
  '';
  
  # Enable developer-friendly options
  programs.bash.enableCompletion = true;
  programs.fish.enable = true;
  programs.zsh.enable = true;
  
  # Enable nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Docker for container development (optional)
  virtualisation.docker.enable = true;
} 