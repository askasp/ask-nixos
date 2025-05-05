{config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.webhook-deploy;
  deployScript = pkgs.writeShellScriptBin "amino-deploy" ''
    #!/bin/sh
    set -e
    
    # Default branch
    BRANCH="''${1:-main}"
    # Service to redeploy, empty means rebuild entire system
    SERVICE="''${2:-}"
    # Branch for amino-api if needed
    API_BRANCH="''${3:-main}"
    
    echo "Received webhook, updating services using branch: $BRANCH..."
    
    # Update amino-app repository if configured
    if [ -d "${cfg.aminoAppRepoPath}" ]; then
      echo "Updating amino-app repository..."
      cd "${cfg.aminoAppRepoPath}"
      git fetch origin
      git checkout "$BRANCH"
      git pull origin "$BRANCH"
      echo "Amino app updated to branch: $BRANCH"
    else
      echo "Warning: Amino app repository not found at ${cfg.aminoAppRepoPath}"
    fi
    
    # Update flake.nix if a different branch is specified for amino-api
    if [ "$API_BRANCH" != "main" ] && [ -f "/etc/nixos/flake.nix" ]; then
      echo "Updating amino-api branch in flake.nix to: $API_BRANCH"
      cd /etc/nixos
      
      # Backup the current flake.nix
      cp flake.nix flake.nix.backup
      
      # Use sed to replace the branch in the amino-api input
      # This pattern looks for the amino-api url line and replaces main with the specified branch
      sed -i "s|url = \"git+ssh://git@github.com/AminoNordics/amino_api.git?ref=refs/heads/main\"|url = \"git+ssh://git@github.com/AminoNordics/amino_api.git?ref=refs/heads/$API_BRANCH\"|g" flake.nix
      
      echo "Updated flake.nix to use amino-api branch: $API_BRANCH"
    fi
    
    # Handle specific service redeployment
    if [ ! -z "$SERVICE" ]; then
      echo "Redeploying specific service: $SERVICE"
      
      case "$SERVICE" in
        "amino-app")
          echo "Redeploying amino-app frontend..."
          cd /etc/nixos
          nixos-rebuild switch --flake .${cfg.flakeTarget} ${optionalString cfg.allowDirty "--option allow-dirty true"}
          ;;
        "amino-api")
          echo "Redeploying amino-api service with branch: $API_BRANCH..."
          cd /etc/nixos
          nixos-rebuild switch --flake .${cfg.flakeTarget} ${optionalString cfg.allowDirty "--option allow-dirty true"}
          ;;
        "cqrs-server")
          echo "Redeploying cqrs-server service..."
          # CQRS server also needs a full rebuild if the branch changed
          if [ "$API_BRANCH" != "main" ]; then
            cd /etc/nixos
            nixos-rebuild switch --flake .${cfg.flakeTarget} ${optionalString cfg.allowDirty "--option allow-dirty true"}
          else
            systemctl restart cqrs-server
          fi
          ;;
        "caddy")
          echo "Reloading Caddy configuration..."
          systemctl reload caddy
          ;;
        *)
          echo "Unknown service: $SERVICE, falling back to full system rebuild"
          cd /etc/nixos
          nixos-rebuild switch --flake .${cfg.flakeTarget} ${optionalString cfg.allowDirty "--option allow-dirty true"}
          ;;
      esac
    else
      # Rebuild entire system using flakes
      echo "Rebuilding entire system..."
      cd /etc/nixos
      nixos-rebuild switch --flake .${cfg.flakeTarget} ${optionalString cfg.allowDirty "--option allow-dirty true"}
    fi
    
    # Restore the original flake.nix if we modified it and want to keep main as default
    if [ "$API_BRANCH" != "main" ] && [ -f "/etc/nixos/flake.nix.backup" ] && [ "${toString cfg.restoreFlakeAfterDeploy}" = "1" ]; then
      echo "Restoring original flake.nix to use main branch..."
      cd /etc/nixos
      mv flake.nix.backup flake.nix
    else
      # Clean up the backup if we're keeping the changes
      rm -f /etc/nixos/flake.nix.backup
    fi
    
    echo "Deployment complete!"
  '';
in {
  options.services.webhook-deploy = {
    enable = mkEnableOption "Webhook deployment service";
    
    port = mkOption {
      type = types.port;
      default = 9000;
      description = "Port to listen for webhooks on";
    };
    
    secretToken = mkOption {
      type = types.str;
      default = "change-me-please";
      description = "Secret token to validate webhooks";
    };
    
    flakeTarget = mkOption {
      type = types.str;
      default = "";
      description = "Flake target to use (e.g., '#hostname' or empty string for default)";
    };
    
    allowDirty = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to allow building with uncommitted changes";
    };
    
    aminoAppRepoPath = mkOption {
      type = types.str;
      default = "/var/lib/amino-app";
      description = "Path to the amino-app git repository";
    };

    restoreFlakeAfterDeploy = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to restore flake.nix to use main branches after deployment";
    };
  };

  config = mkIf cfg.enable {
    # Ensure the webhook package is available
    environment.systemPackages = with pkgs; [
      webhook
      deployScript
      git # Required for repository updates
    ];
    
    # Create the repository directory with proper permissions
    system.activationScripts.createAminoAppRepo = ''
      mkdir -p "${cfg.aminoAppRepoPath}"
      chmod 755 "${cfg.aminoAppRepoPath}"
      
      # Initialize git repo if it doesn't exist
      if [ ! -d "${cfg.aminoAppRepoPath}/.git" ]; then
        cd "${cfg.aminoAppRepoPath}"
        ${pkgs.git}/bin/git init
        ${pkgs.git}/bin/git remote add origin "https://github.com/AminoNordics/amino.git"
        ${pkgs.git}/bin/git fetch origin
        ${pkgs.git}/bin/git checkout -b main origin/main
      fi
    '';
    
    systemd.services.webhook-deploy = {
      description = "Webhook deployment service";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.webhook}/bin/webhook \
            -hooks ${pkgs.writeText "hooks.json" (builtins.toJSON [{
              id = "amino-deploy";
              execute-command = "${deployScript}/bin/amino-deploy";
              pass-arguments-to-command = [
                {
                  source = "payload";
                  name = "branch";
                  default = "main";
                }
                {
                  source = "payload";
                  name = "service";
                }
                {
                  source = "payload";
                  name = "api_branch";
                  default = "main";
                }
              ];
              command-working-directory = "/tmp";
              trigger-rule = {
                match = {
                  type = "value";
                  value = cfg.secretToken;
                  parameter = {
                    source = "header";
                    name = "X-Hub-Signature";
                  };
                };
              };
            }])} \
            -verbose \
            -port ${toString cfg.port}
        '';
        Restart = "on-failure";
        RestartSec = "5s";
        
        # Security hardening with some adjustments to allow Git operations
        DynamicUser = false; # Need stable user for Git
        User = "webhook";
        Group = "webhook";
        PrivateTmp = true;
        ProtectSystem = "strict";
        NoNewPrivileges = true;
        ReadWritePaths = [ 
          cfg.aminoAppRepoPath 
          "/etc/nixos"
        ];
      };
    };
    
    # Create webhook user/group
    users.users.webhook = {
      isSystemUser = true;
      group = "webhook";
      description = "Webhook deployment service user";
    };
    
    users.groups.webhook = {};
    
    # Open the webhook port
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
} 