{config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.amino-api;
in {
  config = mkIf cfg.enable {
    # Define secrets for Amino API
    age.secrets.amino-api-env = {
      file = ../../secrets/amino-api.env.age;
      owner = cfg.user;
      group = cfg.group;
      mode = "0400";
    };

    # Update the Amino API service to use the secrets
    services.amino-api.environmentFile = config.age.secrets.amino-api-env.path;
  };
} 