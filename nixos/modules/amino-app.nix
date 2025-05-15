{pkgs, config, lib, inputs, ...}:

with lib;

let
  cfg = config.services.amino-app;
  # Create a simple package that serves the amino-app directory
  aminoAppPackage = pkgs.stdenv.mkDerivation {
    name = "amino-app";
    version = "1.0.0";
    src = inputs.amino-app;
    buildInputs = [ pkgs.nodejs_22 ];
    nativeBuildInputs = [ pkgs.nodejs_22 ];
    
    # Add environment variables for npm
    NPM_CONFIG_LOGLEVEL = "verbose";
    NPM_CONFIG_PROGRESS = "true";
    NPM_CONFIG_FETCH_RETRIES = "10";
    NPM_CONFIG_FETCH_RETRY_FACTOR = "2";
    NPM_CONFIG_FETCH_RETRY_MINTIMEOUT = "30000";
    NPM_CONFIG_FETCH_RETRY_MAXTIMEOUT = "120000";
    NPM_CONFIG_FETCH_TIMEOUT = "300000";
    
    buildPhase = ''
      # Create a temporary directory for npm
      export HOME=$TMPDIR
      export NPM_CONFIG_CACHE=$TMPDIR/.npm
      export NPM_CONFIG_PREFIX=$TMPDIR/.npm
      
      # Set npm registry to use a more reliable mirror
      export NPM_CONFIG_REGISTRY="https://registry.npmmirror.com/"
      
      # Clear npm cache and set timeout
      npm cache clean --force
      npm config set fetch-timeout 300000
      npm config set fetch-retries 10
      npm config set fetch-retry-factor 2
      npm config set fetch-retry-mintimeout 30000
      npm config set fetch-retry-maxtimeout 120000
      
      # Add network debugging
      echo "Network configuration:"
      npm config list
      
      echo "Starting npm install..."
      # Run npm install with verbose output and network debugging
      npm install --verbose --no-audit --no-fund --no-package-lock --prefer-offline
      
      echo "Starting npm build..."
      # Run build with verbose output
      npm run build --verbose
    '';
    
    installPhase = ''
      # Copy the built files to the output directory
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
    
    # Add a timeout to the build
    buildTimeout = 3600; # 1 hour timeout
    
    # Enable network access
    __noChroot = true;
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
