{ config, lib, pkgs, ... }:

{
  # Keep the standard PostgreSQL service disabled
  services.postgresql.enable = lib.mkForce false;
  
  # Configure MongoDB 
  services.mongodb = {
    enable = true;
    package = pkgs.mongodb;
    bind_ip = "127.0.0.1";
  };

  # Simple custom PostgreSQL service
  systemd.services.postgresql = {
    description = "PostgreSQL Database Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    # Quick preStart script to set up database if needed
    preStart = ''
      # Create data directory if it doesn't exist
      if [ ! -d /var/lib/postgresql/16 ]; then
        mkdir -p /var/lib/postgresql/16
        chown -R postgres:postgres /var/lib/postgresql/16
        chmod 0700 /var/lib/postgresql/16
        
        # Initialize the database
        su - postgres -c "${pkgs.postgresql_16}/bin/initdb -D /var/lib/postgresql/16"
        
        # Basic configuration
        echo "listen_addresses = '127.0.0.1'" >> /var/lib/postgresql/16/postgresql.conf
        echo "port = 5432" >> /var/lib/postgresql/16/postgresql.conf
        
        # Trust local connections initially for setup
        cat > /var/lib/postgresql/16/pg_hba.conf << EOF
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
EOF
      fi
    '';
    
    # Basic service config with short timeout
    serviceConfig = {
      Type = "simple";
      User = "postgres";
      Group = "postgres";
      ExecStart = "${pkgs.postgresql_16}/bin/postgres -D /var/lib/postgresql/16";
      TimeoutStartSec = "30s";  # Short timeout
      TimeoutStopSec = "30s";   # Short timeout
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
  
  # Ensure postgres user exists
  users.users.postgres = {
    isSystemUser = true;
    group = "postgres";
    home = "/var/lib/postgresql";
    createHome = true;
    uid = config.ids.uids.postgres;
    shell = "${pkgs.bash}/bin/bash";
  };
  
  users.groups.postgres = {
    gid = config.ids.gids.postgres;
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