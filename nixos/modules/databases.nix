{ config, lib, pkgs, ... }:

{
  # Database services module - MongoDB and PostgreSQL

  # Enable MongoDB service
  services.mongodb = {
    enable = true;
    package = pkgs.mongodb;
    bind_ip = "127.0.0.1";
  };

  # Enable PostgreSQL service
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all md5
      host all all 127.0.0.1/32 md5
      host all all ::1/128 md5
    '';
  };

  # Create data directories with proper permissions
  system.activationScripts.dbData = ''
    mkdir -p /var/lib/services/data/mongodb
    mkdir -p /var/lib/services/data/postgresql
    
    # Set correct ownership
    if id mongodb &>/dev/null; then
      chown -R mongodb:mongodb /var/lib/services/data/mongodb
    fi
    
    if id postgres &>/dev/null; then
      chown -R postgres:postgres /var/lib/services/data/postgresql
    fi
  '';

  # Install database client tools
  environment.systemPackages = with pkgs; [
    mongodb-tools  # MongoDB client tools (mongodump, etc.)
    mongosh        # MongoDB shell client
    mongodb        # Full MongoDB package including mongo shell
    pgcli          # Better PostgreSQL CLI client
    postgresql_16  # PostgreSQL client tools (psql, etc.)
  ];
} 