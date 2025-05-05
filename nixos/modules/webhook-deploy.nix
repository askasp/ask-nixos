{config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.webhook-deploy;
  deployScript = pkgs.writeShellScriptBin "amino-deploy" ''
    #!/bin/sh
    set -e
    
    # Default branch
    BRANCH="''${1:-main}"
    
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
    
    # Rebuild system using flakes
    cd /etc/nixos
    nixos-rebuild switch --flake .${cfg.flakeTarget} ${optionalString cfg.allowDirty "--option allow-dirty true"}
    
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