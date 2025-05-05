{config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.cqrs-server;
  apiDomain = "apiv2.amino.stadler.no";
in {
  config = mkIf (cfg.enable && config.services.caddy.enable) {
    # Add Caddy virtual host for CQRS Server
    services.caddy.virtualHosts.${apiDomain} = {
      # For development/testing, use internal certificates
      # For production, Caddy will automatically get Let's Encrypt certificates
      extraConfig = ''
        reverse_proxy localhost:${toString cfg.port}
        
        # Enable TLS with internal certs for testing
        # Comment this line for production to use auto Let's Encrypt
        tls internal
        
        # Enable CORS headers
        header {
          Access-Control-Allow-Origin *
          Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
          Access-Control-Allow-Headers "Content-Type, Authorization"
          # Increase security
          Strict-Transport-Security "max-age=31536000; includeSubDomains;"
          X-XSS-Protection "1; mode=block"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          # Cache static assets
          Cache-Control "public, max-age=3600"
        }
        
        # Enable logging
        log {
          output file /var/log/caddy/${apiDomain}.log
          level INFO
        }
      '';
    };
  };
} 