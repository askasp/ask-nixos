{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    # Use minimal installation media
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    
    # Include our SSH module
    ./modules/ssh.nix
  ];

  # Allow unfree packages (for firmware, drivers, etc.)
  nixpkgs.config.allowUnfree = true;
  
  # Use a stable kernel version to avoid issues
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Disable ZFS to avoid "broken" package issues
  boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" "ext4" "vfat" ];
  boot.kernelModules = lib.mkForce [ ];  # Don't include any extra kernel modules by default
  
  # ISO-specific settings
  isoImage.edition = "cirrus-iso";
  isoImage.compressImage = true;
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  
  # Allow root login temporarily for ISO (will be disabled in the final system)
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  
  # Enable password authentication for the ISO
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;
  
  # Set password for the root user - use ONLY initialPassword to avoid conflicts
  users.users.root = {
    # Use initialPassword and override any other password attributes
    initialPassword = lib.mkForce "nixos";
    # Explicitly set other password attributes to null to avoid conflicts
    password = lib.mkForce null;
    hashedPassword = lib.mkForce null;
    passwordFile = lib.mkForce null;
    hashedPasswordFile = lib.mkForce null;
    initialHashedPassword = lib.mkForce null;
  };
  
  # Add SSH keys for easy access during installation
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpB1XsuiQeP6q95awWAp6RBOd0r246yLHTVUzcgJPa7 aksel@stadler.no"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHmnS0jYaPh8bx7c5J4Wt5mpNQLi5JSJv4eDwBdcBh1D u0_a123@localhost"
  ];
  
  # Set hostname for the ISO
  networking.hostName = "cirrus-iso";
  
  # Enable WiFi Support
  networking.wireless = {
    enable = true;  # Enable wpa_supplicant for minimal ISO
    userControlled.enable = true;
  };
  
  # Enable NetworkManager as well for easier wifi configuration
  networking.networkmanager = {
    enable = true;
    wifi.backend = "wpa_supplicant";  # More compatible with minimal ISO
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
    wpa_supplicant
    wirelesstools
    iw
    inetutils
    
    # For network diagnostics
    ethtool
    pciutils
    usbutils
  ];
  
  # Disable various services to simplify the ISO
  services.xserver.enable = lib.mkForce false;
  services.pipewire.enable = lib.mkForce false;
  hardware.pulseaudio.enable = lib.mkForce false;
  
  # Enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Try to download missing packages on build
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://nixos-cache.cachix.org" 
  ];
  
  system.stateVersion = "23.11";
} 