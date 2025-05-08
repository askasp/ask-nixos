# Service Definitions

This directory contains NixOS modules for individual services.
Each service should have its own file and be imported in the main configuration.

## Adding a New Service

1. Create a new file for your service: `my-service.nix`
2. Define the service with its own system user
3. Import it in the main configuration
4. Run `sudo nixos-rebuild switch`

## Service Template

```nix
{ config, lib, pkgs, ... }:

{
  # Service-specific user (recommended for isolation)
  users.users.my-service = {
    isSystemUser = true;
    group = "my-service";
    description = "My Service User";
    home = "/var/lib/services/data/my-service";
  };
  users.groups.my-service = {};
  
  # Define the service
  systemd.services.my-service = {
    description = "My Service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    
    serviceConfig = {
      User = "my-service";
      Group = "my-service";
      WorkingDirectory = "/var/lib/services/data/my-service";
      ExecStart = "...";
      Restart = "on-failure";
      # Security hardening
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };
}
```
