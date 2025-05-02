{config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.webhook-deploy;
  deployScript = pkgs.writeShellScriptBin "amino-deploy" ''
    #!/bin/sh
    set -e
    
    echo "Received webhook, updating Amino API..."
    
    # Update local repo
    cd ${cfg.repoPath}
    git pull
    
    # Rebuild system
    cd /etc/nixos
    nixos-rebuild switch --option allow-dirty true
    
    echo "Deployment complete!"
  '';
in {
  options.services.webhook-deploy = {
    enable = mkEnableOption "Webhook deployment service";
    
    repoPath = mkOption {
      type = types.path;
      default = "/home/ask/git/amino_api";
      description = "Path to the amino-api git repository";
    };
    
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
  };

  config = mkIf cfg.enable {
    # Ensure the webhook package is available
    environment.systemPackages = with pkgs; [
      webhook
      deployScript
    ];
    
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
        
        # Security hardening
        DynamicUser = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        NoNewPrivileges = true;
      };
    };
    
    # Open the webhook port
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
} 