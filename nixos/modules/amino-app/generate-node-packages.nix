{ pkgs, stdenv, lib }:

stdenv.mkDerivation {
  name = "generate-node-packages";
  src = ./.;
  
  buildInputs = with pkgs; [
    node2nix
    nodejs_22
  ];
  
  buildPhase = ''
    # Generate the Nix expressions
    node2nix --nodejs-22 \
      --input package.json \
      --lock package-lock.json \
      --output node-packages.nix \
      --composition node-composition.nix \
      --node-env node-env.nix
  '';
  
  installPhase = ''
    mkdir -p $out
    cp node-packages.nix $out/
    cp node-composition.nix $out/
    cp node-env.nix $out/
  '';
} 