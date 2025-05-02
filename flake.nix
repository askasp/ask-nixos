{
  description = "NixOS configuration for homeserver";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Reference the Amino API repo as a flake
    amino-api = {
      # Option 1: SSH URL (preferred for production)
      url = "git+ssh://git@github.com/AminoNordics/amino_api.git?ref=main";
      # Option 2: Local path (good for development)
      # url = "path:/home/ask/git/amino_api";
      # Now it's a flake
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, agenix, amino-api, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (localSystem: 
      let
        system = "x86_64-linux"; # Target system for NixOS
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # Things that can build on any system
        formatter = nixpkgs.legacyPackages.${localSystem}.nixpkgs-fmt;
      }
    ) // {
      # NixOS configurations (only for x86_64-linux)
      nixosConfigurations = {
        iso = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./nixos/iso.nix
            agenix.nixosModules.default
          ];
        };

        cirrus = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./nixos/cirrus.nix
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            {
               home-manager.useGlobalPkgs = true;
               home-manager.useUserPackages = true;
            }
          ];
        };
      };

      # ISO image build (only available on x86_64-linux)
      packages.x86_64-linux.iso = self.nixosConfigurations.iso.config.system.build.isoImage;
    };
}
