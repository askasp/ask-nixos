{ config, lib, pkgs, ... }:

{
  # Configure the age-encrypted secrets for Amino API
  age.secrets.amino-api-keys = {
    file = ../../secrets/amino-api-keys.age;
    owner = config.services.amino-api.user;
    group = config.services.amino-api.group;
    mode = "0400"; # Read-only by owner
  };
  
  # Configure the amino-api service to use the secret
  services.amino-api = {
    environmentFile = config.age.secrets.amino-api-keys.path;
  };
} 