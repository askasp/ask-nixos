{config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.amino-api;
  apiDomain = "api.amino.stadler.no";
in {
  config = mkIf (cfg.enable && config.services.caddy.enable) {
    # Add Caddy virtual host for Amino API
    services.caddy.virtualHosts.${apiDomain} = {
      extraConfig = ''
        # Use ACME staging for testing
        tls {
          issuer acme {
            preferred_chains smallest
            # Use Let's Encrypt staging for testing
            ca https://acme-staging-v02.api.letsencrypt.org/directory
          }
        }
        
        reverse_proxy localhost:${toString cfg.port}
        
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