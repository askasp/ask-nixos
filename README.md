# NixOS Homeserver Configuration

This repository contains the NixOS configuration for my homeserver, codenamed Cirrus.

## Structure

- `flake.nix`: Defines the Nix flake inputs and outputs.
- `nixos/`: Contains NixOS system configurations.
  - `iso.nix`: Configuration for building a bootable NixOS installer ISO.
  - `cirrus.nix`: Main configuration for the Cirrus homeserver.
  - `modules/`: Reusable NixOS modules for different functionalities (desktop, development, services, etc.).
- `secrets/`: Directory managed by `agenix` for storing secrets. Contains `secrets.nix` (defines secrets) and encrypted `.age` files (ignored by git).
- `home/`: (Optional) Contains Home Manager configurations for user-specific setups.

## Outputs

- `nixosConfigurations.iso`: Builds the NixOS system configuration for the installer ISO.
- `nixosConfigurations.cirrus`: Builds the NixOS system configuration for the Cirrus server.
- `packages.x86_64-linux.iso`: Builds the actual bootable ISO image (`nixosConfigurations.iso.config.system.build.isoImage`).
- `formatter.x86_64-linux`: Provides `nixpkgs-fmt` for formatting Nix code (`nix fmt`).

## Usage

### Building the ISO

```bash
nix build .#iso
```
The resulting ISO file will be in `./result/iso/`.

### Building the Server Configuration (for deployment)

```bash
# Example using nixos-rebuild
# Make sure you have SSH access to the target machine
sudo nixos-rebuild switch --flake .#cirrus --target-host root@<server-ip-or-hostname>

# Or build locally (less common for deployment)
nix build .#nixosConfigurations.cirrus.config.system.build.toplevel
```

### Formatting Code

```bash
nix fmt
```

### Managing Secrets (Agenix)

See the `agenix` documentation for details on adding/editing secrets.

1.  **Edit `secrets.nix`**: Define the secrets you need.
2.  **Edit secrets**: `agenix -e <secret_name.age>` (uses `$EDITOR`).
3.  **Rekey secrets**: `agenix -r` (if SSH host keys or user keys change). 