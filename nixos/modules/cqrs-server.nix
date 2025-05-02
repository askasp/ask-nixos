{pkgs, config, lib, ...}:

with lib;

let
  cfg = config.services.cqrs-server;
in {
  options.services.cqrs-server = {
    enable = mkEnableOption "CQRS Server service";
    
    package = mkOption {
      type = types.package;
      description = "The CQRS Server package to use";
    };
    
    user = mkOption {
      type = types.str;
      default = "cqrs-server";
      description = "User account under which the service runs";
    };
    
    group = mkOption {
      type = types.str;
      default = "cqrs-server";
      description = "Group under which the service runs";
    };
    
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/cqrs-server";
      description = "Directory to store CQRS Server data";
    };
    
    port = mkOption {
      type = types.port;
      default = 5151;
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
      description = "CQRS Server service user";
    };
    
    users.groups.${cfg.group} = {};
    
    systemd.services.cqrs-server = {
      description = "CQRS Server Service";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/cqrs_server";
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