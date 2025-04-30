{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    # Use minimal installation media
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Set hostname for the ISO
  networking.hostName = "cirrus-iso";
  
  # Basic network configuration
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false; # Explicitly disable wpa_supplicant
  
  # Add essential packages for installation
  environment.systemPackages = with pkgs; [
    git 
    vim
    curl
    wget
    tmux
    parted
    gptfdisk
    cryptsetup
    networkmanager
  ];

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Set up SSH keys
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpB1XsuiQeP6q95awWAp6RBOd0r246yLHTVUzcgJPa7 aksel@stadler.no"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHmnS0jYaPh8bx7c5J4Wt5mpNQLi5JSJv4eDwBdcBh1D u0_a123@localhost"
  ];

  # Set a simple root password (avoiding multiple password settings)
  users.users.root.initialPassword = "nixos";
  
  # Explicitly override other password options
  users.mutableUsers = true; # Ensure we can change passwords later
  
  # Enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Set system state version
  system.stateVersion = "23.11";
} 