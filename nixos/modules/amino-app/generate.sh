#!/usr/bin/env bash

# Ensure we're in the right directory
cd "$(dirname "$0")"

# Create a temporary directory for the package files
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Clone the amino-app repository
git clone https://github.com/AminoNordics/amino.git "$TMPDIR/amino-app"

# Generate the Nix expressions
cd "$TMPDIR/amino-app"
nix-shell -p node2nix nodejs_22 --run "
  node2nix --nodejs-22 \
    --input package.json \
    --lock package-lock.json \
    --output node-packages.nix \
    --composition node-composition.nix \
    --node-env node-env.nix
"

# Copy the generated files to our module directory
cp node-packages.nix node-composition.nix node-env.nix "$(dirname "$0")" 