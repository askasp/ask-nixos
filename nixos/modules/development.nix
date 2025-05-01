{ config, pkgs, ... }:

let
  # Create a custom LunarVim package
  lunarvim = pkgs.writeShellScriptBin "lvim" ''
    # Launcher script for LunarVim
    exec ${pkgs.neovim}/bin/nvim -u ~/.local/share/lunarvim/lvim/init.lua "$@"
  '';

  # Create a setup script that will be run once on first login
  lunarvim-setup = pkgs.writeShellScriptBin "setup-lunarvim" ''
    # Only run if LunarVim is not already installed
    if [ ! -d "$HOME/.local/share/lunarvim" ]; then
      echo "Installing LunarVim for user $(whoami)..."
      mkdir -p $HOME/.local/share
      ${pkgs.curl}/bin/curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh | bash -s -- --no-install-dependencies
      echo "LunarVim installed successfully!"
    else
      echo "LunarVim is already installed."
    fi
  '';
in
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
    python3
    nodejs
    ripgrep
    fd
    
    # LunarVim setup
    lunarvim-setup
    lunarvim
    
    # Other useful tools
    jq
    tree
    htop
    curl
    wget
  ];
  
  # Add a note to the login message
  users.motd = ''
    Welcome to NixOS!
    
    If this is your first login, run:
    setup-lunarvim
    
    to install LunarVim.
  '';
  
  # Enable developer-friendly options
  programs.bash.completion.enable = true;
  programs.fish.enable = true;
  programs.zsh.enable = true;
  
  # Enable nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Docker for container development (optional)
  virtualisation.docker.enable = true;
} 