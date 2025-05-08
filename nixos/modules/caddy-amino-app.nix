{config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.amino-app;
in {
  config = mkIf (cfg.enable && config.services.caddy.enable) {
    # Add Caddy virtual host for the amino-app
    services.caddy.virtualHosts.${cfg.domain} = {
      extraConfig = ''
        root * ${cfg.package}
        file_server
        
        # Enable TLS with automatic certificates
        # tls internal # Uncomment for testing
        
        # Security headers
        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains;"
          X-XSS-Protection "1; mode=block"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          # Cache static assets
          Cache-Control "public, max-age=3600"
        }
        
        # Enable SPA routing - redirect all requests to index.html except for actual files
        try_files {path} /index.html

        # Enable logging
        log {
          output file /var/log/caddy/${cfg.domain}.log
          level INFO
        }
      '';
    };
  };
} 
