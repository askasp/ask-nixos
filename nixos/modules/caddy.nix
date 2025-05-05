{ config, lib, pkgs, ... }:

{
  # Caddy web server and reverse proxy module
  # This module is prepared but not active by default
  
  services.caddy = {
    enable = lib.mkDefault false;  # Set to false by default, can be overridden in main config
    
    # Use Caddyfile format for easier management
    configFile = lib.mkDefault null;  # Use the virtualHosts option instead
    
    # Ensure we enable the admin API
    enableReload = true;
    
    # Make sure Caddy can get certificates
    email = "aksel@amino.no";  # For Let's Encrypt
    
    # Alternative JSON config approach (more structured but harder to edit)
    # config = {
    #   apps = {
    #     http = {
    #       servers.main = {
    #         listen = [":80"];
    #         # HTTPS is handled automatically by Caddy when domains are configured
    #         
    #         routes = [
    #           {
    #             match = [{
    #               host = ["example.com"];
    #             }];
    #             handle = [{
    #               handler = "reverse_proxy";
    #               upstreams = [{ dial = "localhost:8000"; }];
    #             }];
    #           }
    #           # Add more routes as needed
    #         ];
    #       };
    #     };
    #   };
    # };
  };

  # Open firewall ports
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
  };
  
  # Add Caddy to trusted users (for binding to privileged ports)
  security.acme = {
    acceptTerms = true;
    defaults.email = "aksel@amino.no";  # Required for Let's Encrypt
  };
  
  # Set up default Caddyfile location with appropriate permissions
  system.activationScripts.caddyConfig = ''
    if [ ! -f /var/lib/services/configs/Caddyfile ]; then
      mkdir -p /var/lib/services/configs
      cat > /var/lib/services/configs/Caddyfile << 'EOF'
# Default Caddyfile
# Uncomment and modify as needed

# example.com {
#   reverse_proxy localhost:3000
# }

# another-example.com {
#   root * /var/www/another-example
#   file_server
# }
EOF
      chown root:caddy-admin /var/lib/services/configs/Caddyfile
      chmod 664 /var/lib/services/configs/Caddyfile
    fi
  '';
  
  # Create log directory for Caddy
  system.activationScripts.caddyLogDir = ''
    mkdir -p /var/log/caddy
    chown caddy:caddy /var/log/caddy
    chmod 755 /var/log/caddy
  '';
  
  # Add script to help with Caddy management
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "caddy-reload" ''
      #!/bin/sh
      sudo systemctl reload caddy
    '')
    
    (writeShellScriptBin "caddy-validate" ''
      #!/bin/sh
      ${pkgs.caddy}/bin/caddy validate
    '')
    
    (writeShellScriptBin "caddy-logs" ''
      #!/bin/sh
      sudo journalctl -u caddy -f
    '')
  ];
  
  # Instructions for activation:
  # To activate Caddy, set services.caddy.enable = true in your cirrus.nix
} 