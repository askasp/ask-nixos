{ config, lib, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      # Harden SSH configuration
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    # Generate host keys on first boot if they don't exist
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
  };

  # SSH hardening (optional but recommended)
  security.pam.sshAgentAuth = true;
  
  # Add your firewall rule
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
} 