{ config, lib, pkgs, ... }:

{
  # Forcefully disable the standard PostgreSQL service
  services.postgresql.enable = lib.mkForce false;
  
  # Configure MongoDB 
  services.mongodb = {
    enable = true;
    package = pkgs.mongodb;
    bind_ip = "127.0.0.1";
  };

  # Install database client tools only
  environment.systemPackages = with pkgs; [
    mongodb-tools
    mongosh
    mongodb
    pgcli
    postgresql_16
  ];
  
  # We'll add PostgreSQL back manually after this rebuild succeeds
} 