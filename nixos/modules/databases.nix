{ config, lib, pkgs, ... }:

{
  # PostgreSQL using standard NixOS module
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
    # Very simple initialization script
    initialScript = pkgs.writeText "postgres-init.sql" ''
      CREATE ROLE amino WITH LOGIN PASSWORD 'amino' CREATEDB;
      CREATE DATABASE amino WITH OWNER amino;
      
      -- Amino API specific database and user
      CREATE ROLE amino_api WITH LOGIN PASSWORD 'amino_api' CREATEDB;
      CREATE DATABASE amino_api WITH OWNER amino_api;
    '';
    # Default settings
    settings = {
      max_connections = 100;
      shared_buffers = "128MB";
    };
  };
  
  # Configure MongoDB 
  services.mongodb = {
    enable = true;
    package = pkgs.mongodb;
    bind_ip = "127.0.0.1";
  };

  # Install database client tools
  environment.systemPackages = with pkgs; [
    mongodb-tools
    mongosh
    mongodb
    pgcli
    postgresql_16
  ];
} 