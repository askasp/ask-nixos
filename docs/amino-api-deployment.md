# Deploying Amino API with NixOS

This document outlines how to deploy the Amino API Rust webserver as a systemd service using NixOS and Nix flakes.

## Prerequisites

1. NixOS with flakes enabled
2. Access to the AminoNordics/amino_api private repository

## Step 1: Initial Setup

The Amino API service is defined in the following files:

- `nixos/modules/amino-api.nix` - The main service module
- `nixos/pkgs/amino-api.nix` - The package definition
- `nixos/modules/agenix-amino-api.nix` - Secret management (using agenix)
- `nixos/modules/caddy-amino-api.nix` - Caddy reverse proxy configuration

## Step 2: Build and Test the Service

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

## Step 3: Setting Up Environment Variables with Agenix

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

## Step 4: Setting Up Caddy Reverse Proxy

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

## Step 5: Updating the Service

When you need to update the Amino API service to a newer version:

1. Update the flake input in `flake.nix`:

```nix
inputs = {
  # ... other inputs
  amino-api = {
    url = "github:AminoNordics/amino_api/new-tag-or-commit";
    flake = false;
  };
};
```

2. Update `cargoHash` in `nixos/pkgs/amino-api.nix` if necessary

3. Rebuild the system:

```bash
sudo nixos-rebuild switch
```

## Troubleshooting

### Service failing to start

Check the logs:

```bash
journalctl -u amino-api -e
```

### Issues with environment variables

Make sure the environment file is properly encrypted:

```bash
ls -la /run/agenix/amino-api-env
```

### Testing the service locally

To test the API directly:

```bash
curl http://localhost:8000/health
```

To test through Caddy:

```bash
curl https://your-domain.com/health
``` 