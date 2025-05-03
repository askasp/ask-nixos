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
  
  # Similar configuration for CQRS server if needed
  age.secrets.cqrs-server-keys = {
    file = ../../secrets/cqrs-server-keys.age;
    owner = config.services.cqrs-server.user;
    group = config.services.cqrs-server.group;
    mode = "0400";
  };
  
  services.cqrs-server = {
    environmentFile = config.age.secrets.cqrs-server-keys.path;
  };
} 