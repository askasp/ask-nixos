{pkgs, config, lib, inputs, ...}:

with lib;

let
  cfg = config.services.amino-app;
  aminoAppPackage = pkgs.stdenv.mkDerivation {
  name = "amino-app";
  version = "1.0.0";
  src = inputs.amino-app; # maybe inputs.amino-app + "/frontend" ?

  buildInputs = with pkgs; [ nodejs_22 python3 gcc ];


  dontUseBuildDir = true;

  buildPhase = ''
    set -x
    echo "=== ENTERED BUILDPHASE ==="
    echo "Working dir: $(pwd)"
    echo "Contents:"
    ls -la
    echo "package.json?"
    cat package.json || (echo "NO package.json!!" && exit 1)

    export HOME=$(mktemp -d)
    export NPM_CONFIG_CACHE=$HOME/.npm
    export PATH="$HOME/.npm/bin:$PATH"
    export NPM_CONFIG_REGISTRY=https://registry.npmjs.org/

    echo "Installing deps"
    npm ci --verbose --no-audit || (echo "npm install failed" && exit 1)

    echo "Running tailwind build"
    npx tailwindcss -i global.css -o ./node_modules/.cache/nativewind/global.css

    echo "Running expo export"
    npx expo export --platform web

    echo "Running npm build"
    npm run build || (echo "Build failed" && exit 1)
  '';

  installPhase = ''
    echo "Copying dist to $out"
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
