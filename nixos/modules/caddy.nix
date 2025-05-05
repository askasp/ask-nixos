{ config, lib, pkgs, ... }:

{
  # Caddy web server and reverse proxy module
  # This module is prepared but not active by default
  
  services.caddy = {
    enable = lib.mkDefault false;  # Set to false by default, can be overridden in main config
    
    # Ensure we enable the admin API
    enableReload = true;
    
    # Make sure Caddy can get certificates
    email = "aksel@amino.no";  # For Let's Encrypt
    
    # virtualHosts configuration will be added in specific service modules
    # like caddy-amino-api.nix
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