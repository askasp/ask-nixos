{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.amino-web;
in {
  options.services.amino-web = {
    enable = mkEnableOption "Amino web app";
    domain = mkOption {
      type = types.str;
      description = "Domain name for the Amino web app";
      example = "amino.example.com";
    };
    port = mkOption {
      type = types.port;
      default = 443;
      description = "Port to serve the Amino web app on";
    };
  };

  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;
      virtualHosts.${cfg.domain} = {
        extraConfig = ''
          root * ${inputs.amino-app.packages.${pkgs.system}.amino-web}
          file_server
          try_files {path} /index.html
          # Listen on the configured port
          listen :${toString cfg.port}
        '';
      };
    };
  };
} 