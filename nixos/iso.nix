{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    # Use minimal installation media
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Allow unfree packages (for firmware, drivers, etc.)
  nixpkgs.config.allowUnfree = true;
  
  # Use a more stable kernel version
  boot.kernelPackages = pkgs.linuxPackages_6_1;
  
  # Explicitly disable problematic filesystems
  boot.supportedFilesystems = [ "btrfs" "ext4" "vfat" "xfs" ];
  
  # ISO-specific settings
  isoImage.edition = "cirrus-iso";
  isoImage.compressImage = true;
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  
  # Set root password for the ISO
  users.users.root.initialPassword = "nixos";
  
  # Set hostname for the ISO
  networking.hostName = "cirrus-iso";
  
  # EXPLICITLY disable wireless.enable to avoid conflicts
  networking.wireless.enable = lib.mkForce false;
  
  # Enable NetworkManager for WiFi
  networking.networkmanager.enable = true;
  
  # Include firmware for WiFi and devices
  hardware.enableRedistributableFirmware = true;
  
  # Include useful tools for installation
  environment.systemPackages = with pkgs; [
    git vim curl wget
    tmux htop
    parted gptfdisk cryptsetup
    networkmanager iw
    pciutils usbutils
  ];
  
  # Enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Set system state version
  system.stateVersion = "23.11";
} 