{ config, lib, pkgs, ... }:

{
  # This module defines a standardized approach for adding services
  
  # Create a directory for service data
  system.activationScripts.serviceData = ''
    mkdir -p /var/lib/services/data
    chown root:service-admin /var/lib/services/data
    chmod 775 /var/lib/services/data
  '';
  
  # Example of how to define a service with its own user
  # Uncomment and modify as needed
  
  # Define a generic web service template
  # users.users.webservice = {
  #   isSystemUser = true;
  #   group = "webservice";
  #   description = "Web Service User";
  #   home = "/var/lib/services/data/webservice";
  # };
  # users.groups.webservice = {};
  
  # systemd.services.web-example = {
  #   description = "Example Web Service";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "network.target" ];
  #   
  #   serviceConfig = {
  #     User = "webservice";
  #     Group = "webservice";
  #     WorkingDirectory = "/var/lib/services/data/webservice";
  #     ExecStart = "${pkgs.nodejs}/bin/node /var/lib/services/data/webservice/server.js";
  #     Restart = "on-failure";
  #     # Security hardening options
  #     ProtectSystem = "strict";
  #     ProtectHome = true;
  #     PrivateTmp = true;
  #     NoNewPrivileges = true;
  #   };
  # };
  
  # Add helper scripts for service management
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "create-service" ''
      #!/bin/sh
      # Script to help create a new service directory structure
      if [ $# -lt 1 ]; then
        echo "Usage: create-service SERVICE_NAME"
        exit 1
      fi
      
      SERVICE_NAME="$1"
      SERVICE_DIR="/var/lib/services/data/$SERVICE_NAME"
      
      if [ -d "$SERVICE_DIR" ]; then
        echo "Service directory already exists: $SERVICE_DIR"
        exit 1
      fi
      
      echo "Creating service directory for $SERVICE_NAME..."
      mkdir -p "$SERVICE_DIR"
      
      # Create a sample service file
      cat > "$SERVICE_DIR/service-info.txt" << EOF
Service Name: $SERVICE_NAME
Created: $(date)
Internal Port: 
Description: 

To configure in Caddy:
1. Edit /var/lib/services/configs/Caddyfile
2. Add your domain configuration
3. Run: caddy-validate && caddy-reload
EOF
      
      # Set proper permissions
      chown -R root:service-admin "$SERVICE_DIR"
      chmod -R 775 "$SERVICE_DIR"
      
      echo "Service directory created at $SERVICE_DIR"
      echo "Next steps:"
      echo "1. Deploy your application to $SERVICE_DIR"
      echo "2. Create a systemd service file in /etc/nixos/nixos/services/$SERVICE_NAME.nix"
      echo "3. Import it in your NixOS configuration"
      echo "4. Update your Caddyfile if needed"
    '')
  ];
} 