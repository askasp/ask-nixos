{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # Hardware detection (needs to be generated on the target system)
    ./hardware-configuration.nix

    # Import all our modules
    ./modules/common.nix
    ./modules/desktop.nix
    ./modules/development.nix
    ./modules/ssh.nix
    ./modules/agenix.nix
    ./modules/caddy.nix
    ./modules/user-management.nix
    ./modules/services.nix
    # Add other modules as needed
  ];

  # Set your hostname
  networking.hostName = "cirrus";

  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Disk management and backups (optional)
  services.fstrim.enable = true;  # Trim SSD periodically

  # Additional services to enable
  services.tailscale.enable = true;  # Private VPN (optional)
  
  # Disable unused SSH settings from the common SSH module if needed
  services.openssh.settings = {
    # Disable root login (safer default)
    PermitRootLogin = "no";
    
    # Use SSH keys instead of passwords (more secure)
    PasswordAuthentication = false;
  };
  
  # Enable service for periodic security updates (optional)
  services.opensnitch.enable = false;  # Application firewall
  
  # Enable automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  
  # Home-manager configuration for user "ask"
  home-manager.users.ask = import ./modules/home-manager/ask.nix;
  
  # Enable automatic installation of LunarVim during activation
  system.activationScripts.installLunarVimDeps = ''
    echo "Ensuring LunarVim dependencies are available..."
    mkdir -p /home/ask/.local/share
    chown -R ask:users /home/ask/.local
  '';
  
  # Create a services directory structure
  system.activationScripts.serviceDirectories = ''
    mkdir -p /etc/nixos/nixos/services
    if [ ! -f /etc/nixos/nixos/services/README.md ]; then
      cat > /etc/nixos/nixos/services/README.md << 'EOF'
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
EOF
    fi
  '';
  
  # This value determines the NixOS release version and should not be changed
  system.stateVersion = "23.11";
} 