{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    # Use graphical installation media with Plasma (KDE)
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-plasma5.nix"
    
    # Include our SSH module
    ./modules/ssh.nix
  ];

  # Allow unfree packages (for firmware, drivers, etc.)
  nixpkgs.config.allowUnfree = true;
  
  # ISO-specific settings
  isoImage.edition = "cirrus-installer";
  isoImage.compressImage = true;
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  
  # Allow root login temporarily for ISO (will be disabled in the final system)
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  
  # Enable password authentication for the ISO
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;
  
  # Set a password for the root user on the ISO
  users.users.root.initialPassword = "nixos";
  
  # Add SSH keys for easy access during installation
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpB1XsuiQeP6q95awWAp6RBOd0r246yLHTVUzcgJPa7 aksel@stadler.no"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHmnS0jYaPh8bx7c5J4Wt5mpNQLi5JSJv4eDwBdcBh1D u0_a123@localhost"
  ];
  
  # Set hostname for the ISO
  networking.hostName = "cirrus-installer";
  
  # Enable WiFi Support
  networking.wireless = {
    enable = false;  # We use NetworkManager instead
    userControlled.enable = true;
  };
  
  # Enable NetworkManager with WiFi support
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";  # Modern WiFi backend
  };
  
  # Include wireless firmware and tools
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  
  # Enable Bluetooth for potential USB tethering needs
  hardware.bluetooth.enable = true;
  
  # Enable useful tools for installation
  environment.systemPackages = with pkgs; [
    git
    vim
    tmux
    wget
    curl
    htop
    parted
    gptfdisk
    cryptsetup
    nix-prefetch-git
    
    # Network tools
    networkmanager
    iwd
    wpa_supplicant
    wirelesstools
    inetutils
    
    # For network diagnostics
    ethtool
    pciutils
    usbutils
  ];
  
  # Enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  system.stateVersion = "23.11";
} 