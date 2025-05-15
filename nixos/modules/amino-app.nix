{pkgs, config, lib, inputs, ...}:

with lib;

let
  cfg = config.services.amino-app;
  
  # Import the node2nix generated expressions
  nodePackages = import ./amino-app/node-composition.nix {
    inherit pkgs;
    inherit (pkgs) stdenv fetchurl fetchgit;
    nodejs = pkgs.nodejs_22;
  };
  
  # Create the package using the generated node2nix expressions
  aminoAppPackage = nodePackages.package.override {
    name = "amino-app";
    version = "1.0.0";
    src = inputs.amino-app;
    
    # Set environment to production
    NODE_ENV = "production";
    
    buildPhase = ''
      # Build the application
      npm run build
    '';
    
    # Copy the built files to the output directory
    installPhase = ''
      mkdir -p $out
      if [ -d "dist" ]; then
        cp -r dist/* $out/
      elif [ -d "build" ]; then
        cp -r build/* $out/
      else
        echo "Error: No dist or build directory found"
        exit 1
      fi
    '';
  };
in {
  options.services.amino-app = {
    enable = mkEnableOption "Amino App frontend web application";
    
    package = mkOption {
      type = types.package;
      default = aminoAppPackage;
      description = "The amino-app package to serve";
    };
    
    domain = mkOption {
      type = types.str;
      default = "app.amino.stadler.no";
      description = "Domain name for the amino-app frontend";
    };
  };

  config = mkIf cfg.enable {
    # Ensure Caddy is enabled when amino-app is enabled
    services.caddy.enable = mkDefault true;
    
    # Create a directory for logs
    systemd.tmpfiles.rules = [
      "d /var/log/caddy 0755 caddy caddy -"
    ];
    
    # Configure Caddy to serve the Amino app
    services.caddy.virtualHosts.${cfg.domain} = {
      extraConfig = ''
        root * ${cfg.package}
        file_server
        
        # Enable TLS with automatic certificates
        tls internal # Using internal TLS for testing
        
        # Security headers
        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains;"
          X-XSS-Protection "1; mode=block"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          # Cache static assets
          Cache-Control "public, max-age=3600"
        }
        
        # Handle SPA routing - all paths that don't exist should serve index.html
        @notFound {
          not file
          not path *.js *.css *.png *.jpg *.jpeg *.gif *.svg *.ico *.woff *.woff2
        }
        
        rewrite @notFound /index.html
        
        # Enable logging with more details
        log {
          output file /var/log/caddy/${cfg.domain}.log
          format json
          level INFO
        }
      '';
    };
    
    # Add a convenience message
    system.activationScripts.amino-app-message = ''
      echo "Amino App is configured at https://${cfg.domain}"
    '';
  };
} 
