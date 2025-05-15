{ config, lib, ... }:

with lib;

let
  cfg = config.services.amino-app;
in {
  options.services.amino-app = {
    enable = mkEnableOption "Amino App frontend web application";
    
    domain = mkOption {
      type = types.str;
      default = "app.amino.stadler.no";
      description = "Domain name for the amino-app frontend";
    };

    rootDir = mkOption {
      type = types.path;
      default = "/var/lib/amino-app/dist";
      description = "Directory containing the built amino-app files";
    };
  };

  config = mkIf cfg.enable {
    services.caddy.enable = mkDefault true;

    systemd.tmpfiles.rules = [
      "d /var/log/caddy 0755 caddy caddy -"
      "d ${cfg.rootDir} 0755 caddy caddy -"
    ];

    system.activationScripts.amino-app-message = ''
      echo "Amino App is configured at https://${cfg.domain}"
      echo "Place your built files in ${cfg.rootDir}"
    '';
  };
}