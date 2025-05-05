{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # Try all possible locations for hardware-configuration.nix
    # Uncomment the one that works for your system
    ./hardware-configuration.nix
    # ../hardware-configuration.nix
    # /etc/nixos/nixos/hardware-configuration.nix

    # Import all our modules
    ./modules/common.nix
    ./modules/desktop.nix
    ./modules/development.nix
    ./modules/ssh.nix
    ./modules/agenix.nix
    ./modules/caddy.nix
    ./modules/user-management.nix
    ./modules/services.nix
    ./modules/databases.nix
    ./modules/amino-api.nix
    ./modules/cqrs-server.nix
    ./modules/webhook-deploy.nix
    # Uncomment this when you're ready to use agenix for secrets
    ./modules/agenix-amino-api.nix
    ./modules/agenix-cqrs-server.nix
    # Add other modules as needed
  ];

  # Set your hostname
  networking.hostName = "cirrus";

  # Enable Nix features for using SSH keys with flakes
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "ask" ];
  };

  # Enable SSH agent to use existing keys
  programs.ssh.startAgent = true;

  # Enable Amino API service
  services.amino-api = {
    enable = true;
    package = inputs.amino-api.packages.${pkgs.system}.amino_api;
    port = 5150;
  };

  # Enable CQRS Server service
  services.cqrs-server = {
    enable = true;
    package = inputs.amino-api.packages.${pkgs.system}.cqrs_server;
    port = 5151;
  };

  # Enable webhook for continuous deployment
  services.webhook-deploy = {
    enable = true;
    repoPath = "/home/ask/git/amino_api";
    port = 9000;
    # Generate a secure token for production
    secretToken = "change-me-in-production";
  };

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
  home-manager = {
    useGlobalPkgs = true;  # Use the system's packages
    useUserPackages = true;  # Merge into the user profile
    users.ask = import ./modules/home-manager/ask.nix;
    
    # Add backup file extension to handle existing files
    backupFileExtension = "backup";
    
    # Give home-manager access to agenix secrets
    extraSpecialArgs = { inherit inputs; };
  };
  
  # Make sure neovim is installed at system level since we disabled it in home-manager
  environment.systemPackages = with pkgs; [
    neovim
    xclip      # For clipboard support in tmux
    fish       # For tmux integration
  ];
  
  # Set default editor to lvim
  environment.variables = {
    EDITOR = "lvim";
    VISUAL = "lvim";
  };
  
  # Enable fish shell
  programs.fish.enable = true;
  
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