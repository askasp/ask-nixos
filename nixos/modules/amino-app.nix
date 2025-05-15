{pkgs, config, lib, inputs, ...}:

with lib;

let
  cfg = config.services.amino-app;
  
  # Simple package that builds the React app
  aminoAppPackage = pkgs.stdenv.mkDerivation {
    name = "amino-app";
    version = "1.0.0";
    src = inputs.amino-app;
    
    buildInputs = with pkgs; [
      nodejs_22
      nodePackages.npm
      python3  # Some npm packages might need Python
      gcc      # For native module compilation
    ];
    
    buildPhase = ''
      # Ensure home directory exists for npm
      export HOME=$(mktemp -d)
      
      # Configure npm
      export NPM_CONFIG_CACHE=$HOME/.npm
      export NPM_CONFIG_PREFIX=$HOME/.npm
      export PATH="$HOME/.npm/bin:$PATH"
      
      # Network configuration
      export NPM_CONFIG_REGISTRY=https://registry.npmjs.org/
      export NPM_CONFIG_FETCH_TIMEOUT=300000  # 5 minutes
      export NPM_CONFIG_FETCH_RETRIES=5
      export NPM_CONFIG_FETCH_RETRY_FACTOR=2
      export NPM_CONFIG_FETCH_RETRY_MINTIMEOUT=10000
      export NPM_CONFIG_FETCH_RETRY_MAXTIMEOUT=60000
      
      # Debug information
      echo "Node version: $(node --version)"
      echo "NPM version: $(npm --version)"
      echo "Current directory: $(pwd)"
      echo "Listing directory contents:"
      ls -la
      
      # Install dependencies with verbose output and network debugging
      echo "Starting npm install..."
      npm install --verbose --no-audit --no-fund --loglevel verbose
      
      # Build the app
      echo "Building with tailwindcss..."
      npx tailwindcss -i global.css -o ./node_modules/.cache/nativewind/global.css
               
      # Build the web export
      echo "Building web export..."
      npx expo export --platform web
    '';
    
    installPhase = ''
      # Copy the build output to the output directory
      mkdir -p $out
      cp -r dist/* $out/
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
        root * ${toString cfg.package}
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
