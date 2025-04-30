{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # Ensure the agenix NixOS module is imported
    inputs.agenix.nixosModules.default
  ];

  # Install the agenix CLI tool 
  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.${pkgs.system}.default
  ];

  # Configure agenix - By default, agenix will look for secrets.nix in the same directory as your flake.nix
  # age.secretsDir = "/run/agenix"; # The default path where agenix will mount secrets

  # Example of how to use an agenix-managed secret:
  # age.secrets.example-secret = {
  #   file = ../secrets/example.age;
  #   owner = "youruser";
  #   group = "users";
  #   mode = "0400";
  # };
} 