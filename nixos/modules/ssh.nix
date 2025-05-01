{ config, lib, pkgs, ... }:

{
  # Secure SSH server configuration
  services.openssh = {
    enable = true;
    settings = {
      # Disable password authentication - require keys only
      PasswordAuthentication = false;
      
      # Disable root login
      PermitRootLogin = "no";
      
      # Disable challenge-response authentication
      KbdInteractiveAuthentication = false;
      
      # Only allow specified users to login via SSH
      AllowUsers = [ "ask" ];
      
      # Additional hardening options
      X11Forwarding = false;
      PermitEmptyPasswords = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
    };
    
    # Generate host keys automatically
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

  # SSH hardening
  security.pam.enableSSHAgentAuth = true;
  
  # Firewall configuration - only allow specified ports
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
    # Drop everything else by default
    defaultPolicy = {
      incoming = "drop";
      outgoing = "accept";
    };
    logRefusedConnections = true;
  };
  
  # Additional security measures
  security.lockKernelModules = false; # Set to true for even more security, but reduces flexibility
  security.protectKernelImage = true;
  boot.kernelParams = [ "lockdown=confidentiality" ]; # Kernel lockdown
  
  # Enable fail2ban to prevent brute force attacks
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.1/8"
      # Add trusted IP ranges here, e.g. "192.168.1.0/24"
    ];
  };
} 