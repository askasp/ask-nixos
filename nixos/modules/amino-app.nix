{ config, lib, ... }:

with lib;

let
  cfg = config.services.amino-app;
in {
  options.services.amino-app = {
    enable = mkEnableOption "Amino App frontend web application";
    
    domain = mkOption {
      type = types.str;
      default = "app.amino.stadler.no";
      description = "Domain name for the amino-app frontend";
    };

    rootDir = mkOption {
      type = types.path;
      default = "/var/lib/amino-app/dist";
      description = "Directory containing the built amino-app files";
    };
  };

  config = mkIf cfg.enable {
    services.caddy.enable = mkDefault true;

    systemd.tmpfiles.rules = [
      "d /var/log/caddy 0755 caddy caddy -"
      "d ${cfg.rootDir} 0755 caddy caddy -"
    ];

    services.caddy.virtualHosts.${cfg.domain} = {
      extraConfig = ''
        root * ${cfg.rootDir}
        file_server
        tls internal
        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains;"
          X-XSS-Protection "1; mode=block"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          Cache-Control "public, max-age=3600"
        }
        @notFound {
          not file
          not path *.js *.css *.png *.jpg *.jpeg *.gif *.svg *.ico *.woff *.woff2
        }
        rewrite @notFound /index.html
        log {
          output file /var/log/caddy/${cfg.domain}.log
          format json
          level INFO
        }
      '';
    };

    system.activationScripts.amino-app-message = ''
      echo "Amino App is configured at https://${cfg.domain}"
      echo "Place your built files in ${cfg.rootDir}"
    '';
  };
}