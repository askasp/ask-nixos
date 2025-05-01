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

  # Configure agenix path - explicitly set to the default
  age.secretsDir = "/run/agenix";

  # Define the Anthropic API key secret
  age.secrets.anthropic-api-key = {
    file = /etc/nixos/secrets/anthropic-api-key.age;
    owner = "ask";
    group = "users";
    mode = "0400";
    # This path is what our home-manager script will look for
    path = "/run/agenix/anthropic-api-key";
  };

  # Example of how to use an agenix-managed secret:
  # age.secrets.example-secret = {
  #   file = ../secrets/example.age;
  #   owner = "youruser";
  #   group = "users";
  #   mode = "0400";
  # };
} 