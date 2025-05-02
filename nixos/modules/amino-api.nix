{pkgs, config, lib, ...}:

with lib;

let
  cfg = config.services.amino-api;
in {
  options.services.amino-api = {
    enable = mkEnableOption "Amino API service";
    
    package = mkOption {
      type = types.package;
      description = "The Amino API package to use";
    };
    
    user = mkOption {
      type = types.str;
      default = "amino-api";
      description = "User account under which the service runs";
    };
    
    group = mkOption {
      type = types.str;
      default = "amino-api";
      description = "Group under which the service runs";
    };
    
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/amino-api";
      description = "Directory to store Amino API data";
    };
    
    port = mkOption {
      type = types.port;
      default = 5150;
      description = "Port to listen on";
    };
    
    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file with secrets";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      description = "Amino API service user";
    };
    
    users.groups.${cfg.group} = {};
    
    systemd.services.amino-api = {
      description = "Amino API Service";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/amino_api-cli start";
        Restart = "on-failure";
        
        # Security hardening
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        
        # Environment
        EnvironmentFile = optional (cfg.environmentFile != null) cfg.environmentFile;
      };
      
      environment = {
        PORT = toString cfg.port;
      };
    };
  };
} 