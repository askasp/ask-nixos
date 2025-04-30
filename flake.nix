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
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, agenix, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        iso = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./nixos/iso.nix
            # Common modules can be added here if needed for the ISO
            agenix.nixosModules.default
          ];
        };
        cirrus = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./nixos/cirrus.nix
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            {
               home-manager.useGlobalPkgs = true;
               home-manager.useUserPackages = true;
               # Define user configuration path if needed, e.g.:
               # home-manager.users.your-username = import ./home/your-username.nix;
            }
            # Add agenix module here
          ];
        };
      };

      # Example ISO image build
      packages.${system}.iso = self.nixosConfigurations.iso.config.system.build.isoImage;

      # Formatter for consistent code style
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
