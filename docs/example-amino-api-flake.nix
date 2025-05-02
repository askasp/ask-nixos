# Example flake.nix for the amino_api repository
# Copy this to the root of the amino_api repo

{
  description = "Amino API - Rust Webserver";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [
          rust-overlay.overlays.default
          (final: prev: {
            rustToolchain = final.rust-bin.stable.latest.default;
          })
        ];
        
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      {
        packages = {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = "amino_api";
            version = "0.1.0";
            
            src = ./.;
            
            cargoLock = {
              lockFile = ./Cargo.lock;
              # If you have git dependencies, specify their hashes:
              # outputHashes = {
              #   "ask-cqrs-0.1.0" = "sha256-HASH_VALUE_HERE";
              # };
            };
            
            nativeBuildInputs = with pkgs; [
              pkg-config
            ];
            
            buildInputs = with pkgs; [
              openssl
              # Add any other dependencies your project needs
            ];
          };
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustToolchain
            pkg-config
            openssl
          ];
        };
      }
    );
} 