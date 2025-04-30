{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    # Use minimal installation media
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Only minimal customization
  networking.hostName = "cirrus-iso";
  
  # Fix root password conflict
  users.users.root = {
    # Only set one password attribute to avoid conflicts
    initialPassword = "nixos";
    # Override all other password options explicitly
    password = lib.mkForce null;
    hashedPassword = lib.mkForce null;
    passwordFile = lib.mkForce null;
    hashedPasswordFile = lib.mkForce null;
    initialHashedPassword = lib.mkForce null;
  };
  
  # Enable flakes and nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
} 