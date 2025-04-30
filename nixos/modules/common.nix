{ config, lib, pkgs, ... }:

{
  # Set your time zone
  time.timeZone = "UTC";  # Change to your timezone, e.g., "America/New_York"

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  # Basic system packages
  environment.systemPackages = with pkgs; [
    # Basic utilities
    curl
    wget
    htop
    git
    vim
    nano
    tmux
    zip
    unzip
    
    # System monitoring
    lm_sensors
    smartmontools
    
    # Network utilities
    iperf
    nmap
    tcpdump
    bind.dnsutils  # dig, nslookup, etc.
  ];

  # Enable Nix flakes
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Optimize nix store
    auto-optimise-store = true;
  };

  # Use the latest Linux kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable system-wide zsh
  programs.zsh.enable = true;
  
  # Set up automatic system upgrades (optional)
  system.autoUpgrade = {
    enable = false;  # Set to true to enable
    allowReboot = false;
    flake = "github:yourusername/ask-nixos";
    flags = [
      "--update-input" "nixpkgs"
      "--commit-lock-file"
    ];
    dates = "weekly";
  };
  
  # Disable documentation for faster builds (optional)
  documentation = {
    enable = true;
    doc.enable = false;  # Disable regular docs
    info.enable = false; # Disable info pages
    man.enable = true;   # Keep manpages
  };
  
  # Enable non-free packages (if needed)
  nixpkgs.config.allowUnfree = true;
  
  # Set system state version
  system.stateVersion = "23.11";
} 