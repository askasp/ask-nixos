{ config, lib, pkgs, ... }:

{
  # Create your personal user account
  users.users.ask = {
    isNormalUser = true;
    description = "Ask";
    extraGroups = [ 
      "wheel"           # Administrator/sudo access
      "networkmanager"  # Manage network settings
      "video" "audio"   # Media devices access
      "docker"          # Docker access (if enabled)
      "caddy-admin"     # Custom group for managing Caddy configs
      "service-admin"   # Group for managing services
    ];
    
    # Add SSH keys for remote access
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpB1XsuiQeP6q95awWAp6RBOd0r246yLHTVUzcgJPa7 aksel@stadler.no"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHmnS0jYaPh8bx7c5J4Wt5mpNQLi5JSJv4eDwBdcBh1D u0_a123@localhost"
    ];
    
    # Set initial password (you should change this after first login)
    initialPassword = "changeThisPassword";
    
    # Use ZSH as the default shell
    shell = pkgs.zsh;
    
    # Create home directory during system activation
    createHome = true;
    home = "/home/ask";
    # Ensure proper permissions
    homeMode = "0750";
  };
  
  # Define additional groups for service management
  users.groups.caddy-admin = {};
  users.groups.service-admin = {};
  
  # Allow passwordless sudo for wheel group (for development convenience)
  security.sudo.wheelNeedsPassword = false;
  
  # Make specific directories writable by the service-admin group
  # This allows your user to manage service configurations
  system.activationScripts.serviceDirs = ''
    mkdir -p /var/lib/services/configs
    chown root:service-admin /var/lib/services/configs
    chmod 775 /var/lib/services/configs
  '';
  
  # Add sudo rules to allow service management without full root
  security.sudo.extraRules = [
    {
      # Allow members of service-admin to manage systemd services
      groups = [ "service-admin" ];
      commands = [
        {
          command = "${pkgs.systemd}/bin/systemctl restart caddy";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/systemctl reload caddy";
          options = [ "NOPASSWD" ];
        }
        # Add other services as needed
      ];
    }
  ];
} 