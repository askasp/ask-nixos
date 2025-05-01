{ config, pkgs, ... }:

let
  # Create a custom LunarVim package with proper environment setup
  lunarvim = pkgs.writeShellScriptBin "lvim" ''
    # Set PATH to include all the necessary LSP servers
    export PATH="${pkgs.rust-analyzer}/bin:$PATH"
    
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
      
      # Create necessary config directories
      mkdir -p $HOME/.config/lvim
      mkdir -p $HOME/.local/share/lvim/mason/bin
      
      # Create symlink to system rust-analyzer
      echo "Creating symlink for rust-analyzer..."
      ln -sf ${pkgs.rust-analyzer}/bin/rust-analyzer $HOME/.local/share/lvim/mason/bin/rust-analyzer
      
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
    
    # Language servers for code completion and analysis
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted # HTML, CSS, JSON, ESLint
    
    # Build essentials
    gcc
    gnumake
    cmake
    pkg-config
    
    # Protocol Buffers
    protobuf  # Includes protoc compiler
    
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
    
    # Add OpenSSL and other libraries needed for Rust development
    openssl
    openssl.dev  # Development headers
    pkg-config   # For finding libraries
  ];
  
  # System-wide environment variables
  environment.variables = {
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
    
    # Add PROTOC environment variable
    PROTOC = "${pkgs.protobuf}/bin/protoc";
    
    # Ensure rust-analyzer is in PATH
    PATH = ["${pkgs.rust-analyzer}/bin" "$PATH"];
  };
  
  # Add a system-wide shell script to ensure OpenSSL environment is always set
  environment.etc."profile.d/rust-openssl.sh" = {
    text = ''
      export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
      export OPENSSL_DIR="${pkgs.openssl.dev}"
      export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
      export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
      export PROTOC="${pkgs.protobuf}/bin/protoc"
    '';
    mode = "0644";
  };
  
  # Add a note to the login message
  users.motd = ''
    Welcome to NixOS!
    
    If this is your first login, run:
    setup-lunarvim
    
    Rust development with OpenSSL and Protocol Buffers is pre-configured.
  '';
  
  # Enable developer-friendly options
  programs.bash.completion.enable = true;
  programs.fish.enable = true;
  programs.zsh.enable = true;
  
  # Enable nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Docker for container development (optional)
  virtualisation.docker.enable = true;
  
  # Enable unfree packages if needed
  nixpkgs.config.allowUnfree = true;
} 