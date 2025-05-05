{pkgs, inputs}:

pkgs.stdenv.mkDerivation {
  name = "amino-app";
  src = inputs.amino-app; # Using the amino-app input defined in flake.nix
  
  nativeBuildInputs = with pkgs; [ 
    nodejs
    nodePackages.npm
  ];
  
  buildPhase = ''
    # Set up npm to install packages in the build directory
    export HOME=$PWD
    npm ci
    
    # Process TailwindCSS
    npx tailwindcss -i global.css -o ./node_modules/.cache/nativewind/global.css
    
    # Set RELEASE_DIR to point to a temporary directory in the build
    export RELEASE_DIR="$PWD/dist"
    
    # Build the Expo web app
    npx expo export --platform web --output-dir "$RELEASE_DIR"
  '';
  
  installPhase = ''
    # Copy the Expo web output to the Nix output directory
    mkdir -p $out
    cp -r $RELEASE_DIR/* $out/
  '';
} 