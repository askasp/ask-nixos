# Deploying Amino API with NixOS

This document outlines how to deploy the Amino API Rust webserver as a systemd service using NixOS and Nix flakes.

## Prerequisites

1. NixOS with flakes enabled
2. Access to the AminoNordics/amino_api private repository with its flake.nix

## Step 1: Initial Setup

The Amino API service is defined in the following files:

- `nixos/modules/amino-api.nix` - The service module that configures systemd
- `nixos/modules/agenix-amino-api.nix` - Secret management (using agenix)
- `nixos/modules/caddy-amino-api.nix` - Caddy reverse proxy configuration

## Step 2: Clone the Repository

Since we're using a local path reference, clone the amino_api repository:

```bash
# Make sure the directory exists
mkdir -p /home/ask/git

# Clone the repository 
git clone git@github.com:AminoNordics/amino_api.git /home/ask/git/amino_api
```

## Step 3: Build and Test the Service

1. First, rebuild the system to add the service:

```bash
sudo nixos-rebuild switch
```

2. Check if the service is running:

```bash
systemctl status amino-api
```

3. View the logs:

```bash
journalctl -u amino-api -f
```

## Step 4: Setting Up Environment Variables with Agenix

### First-time setup

1. Copy the environment variable template:

```bash
cp secrets/amino-api.env.template secrets/amino-api.env
```

2. Edit the environment file with your credentials:

```bash
vim secrets/amino-api.env
```

3. Encrypt it using agenix:

```bash
agenix -e secrets/amino-api.env.age
```

4. Uncomment the agenix-amino-api module in `nixos/cirrus.nix`:

```nix
imports = [
  # ... other imports
  ./modules/amino-api.nix
  ./modules/agenix-amino-api.nix
];
```

5. Rebuild the system:

```bash
sudo nixos-rebuild switch
```

## Step 5: Setting Up Caddy Reverse Proxy

1. Update the domain in `nixos/modules/caddy-amino-api.nix` with your actual domain:

```nix
let
  cfg = config.services.amino-api;
  domain = "your-actual-domain.com";
in {
  # ...
}
```

2. Import the caddy-amino-api module in your `nixos/cirrus.nix`:

```nix
imports = [
  # ... other imports
  ./modules/amino-api.nix
  ./modules/agenix-amino-api.nix
  ./modules/caddy-amino-api.nix
];
```

3. Rebuild the system:

```bash
sudo nixos-rebuild switch
```

## Step 6: Continuous Deployment with Webhooks

The webhook deployment service will automatically:
1. Pull the latest changes from your git repository
2. Rebuild the NixOS system
3. Restart the amino-api service

To set up a webhook in GitHub:

1. Go to your repository settings > Webhooks
2. Add a new webhook:
   - Payload URL: `http://your-server:9000/hooks/amino-deploy`
   - Content type: `application/json`
   - Secret: (The value in your config, defaults to "change-me-in-production")
   - Events: Just the `push` event

## Troubleshooting

### Service failing to start

Check the logs:

```bash
journalctl -u amino-api -e
```

### Issues with flake inputs

If you're having trouble with the flake, you can try:

```bash
# Update the flake lock file
cd /etc/nixos
sudo nix flake update

# Or update just the amino-api input
sudo nix flake lock --update-input amino-api
```

### Testing the service locally

To test the API directly:

```bash
curl http://localhost:5150/health
```

To test through Caddy:

```bash
curl https://your-domain.com/health
``` 