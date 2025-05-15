{pkgs, config, lib, inputs, ...}:

with lib;

let
  cfg = config.services.amino-app;
  
  # Generate node2nix files
  node2nixFiles = pkgs.runCommand "node2nix-files" {} ''
    ${pkgs.node2nix}/bin/node2nix \
      --input ${inputs.amino-app}/package.json \
      --lock ${inputs.amino-app}/package-lock.json \
      --output default.nix \
      --composition composition.nix \
      --node-env node-env.nix
    
    mkdir -p $out
    cp default.nix $out/
    cp composition.nix $out/
    cp node-env.nix $out/
  '';

  # Get node dependencies
  nodeDependencies = (pkgs.callPackage "${node2nixFiles}/default.nix" {}).nodeDependencies;

  # Simple package that builds the React app
  aminoAppPackage = pkgs.stdenv.mkDerivation {
    name = "amino-app";
    version = "1.0.0";
    src = inputs.amino-app;
    
    buildInputs = with pkgs; [
      nodejs_22
      nodePackages.npm
    ];
    
    buildPhase = ''
      # Ensure home directory exists for npm
      export HOME=$(mktemp -d)
      
      # Link node modules and add to PATH
      ln -s ${nodeDependencies}/lib/node_modules ./node_modules
      export PATH="${nodeDependencies}/bin:$PATH"
      
      # Build the app
      npx tailwindcss -i global.css -o ./node_modules/.cache/nativewind/global.css
               
      # Build the web export
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
