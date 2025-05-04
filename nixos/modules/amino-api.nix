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
      after = ["network.target" "postgresql.service" "mongodb.service"];
      requires = ["postgresql.service" "mongodb.service"];
      
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
        LOG_LEVEL = "info";
        NODE_ENV = "production";
        HOST = "0.0.0.0";
        
        # Added environment variables (non-sensitive)
        PERIODE_API_URL = "https://europe-west1-periode-test.cloudfunctions.net/merchantApi";
        PERIODE_MERCHANT_ID = "LrKXxsdgN3nFA4z6aL9M";
        PERIODE_PRODUCT_ID = "RnHNOfpTk8Ed8TjaTtT9";
        
        GOOGLE_CLIENT_ID = "609720994907-1n1s9mie9j1p33hrv5rs2q30k6todk8i.apps.googleusercontent.com";
        GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
        GOOGLE_AUTHORIZATION_URL = "https://accounts.google.com/o/oauth2/v2/auth";
        GOOGLE_USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo";
        GOOGLE_CALLBACK_URL = "https://app.amino-dev.akselerasjon.no/auth/google/callback";
        GOOGLE_MERGE_CALLBACK_URL = "https://api.amino-dev.akselerasjon.no/api/auth/callback/merge";
        
        CRIIPTO_CLIENT_ID = "urn:my:application:identifier:959065";
        CRIIPTO_AUTHORIZATION_URL = "https://amino-test.criipto.id/oauth2/authorize";
        CRIIPTO_TOKEN_URL = "https://amino-test.criipto.id/oauth2/token";
        CRIIPTO_USERINFO_URL = "https://amino-test.criipto.id/oauth2/userinfo";
        CRIIPTO_CALLBACK_URL = "https://app.amino.akselerasjon.no/auth/criipto/callback";
        CRIIPTO_MERGE_CALLBACK_URL = "https://api.amino-dev.akselerasjon.no/api/auth/callback/merge";
        
        REDIS_URL = "redis://redis:6379";
        
        # Add ENV variable
        ENV = "dev";
      };
    };
  };
} 