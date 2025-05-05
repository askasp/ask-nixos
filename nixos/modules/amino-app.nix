{pkgs, config, lib, inputs, ...}:

with lib;

let
  cfg = config.services.amino_app;
in {
  options.services.amino_app = {
    enable = mkEnableOption "Amino App frontend web application";
    
    package = mkOption {
      type = types.package;
      description = "The amino_app package to serve";
    };
    
    domain = mkOption {
      type = types.str;
      default = "app.amino.stadler.no";
      description = "Domain name for the amino_app frontend";
    };
  };

  config = mkIf cfg.enable {
    # No service needed since we're just serving static files with Caddy
  };
} 