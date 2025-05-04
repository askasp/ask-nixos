{ config, lib, pkgs, ... }:

{
  # Configure the age-encrypted secrets for CQRS server
  age.secrets.cqrs-server-keys = {
    file = ../../secrets/cqrs-server-keys.age;
    owner = config.services.cqrs-server.user;
    group = config.services.cqrs-server.group;
    mode = "0400"; # Read-only by owner
  };
  
  # Configure the CQRS server service to use the secret
  services.cqrs-server = {
    environmentFile = config.age.secrets.cqrs-server-keys.path;
  };
} 