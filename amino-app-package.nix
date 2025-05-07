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
    echo "Starting build in $PWD"
    echo "Contents of directory:"
    ls -la
    
    echo "Installing dependencies..."
    npm ci
    
    echo "Processing TailwindCSS..."
    npx tailwindcss -i global.css -o ./node_modules/.cache/nativewind/global.css
    
    # Set RELEASE_DIR to point to a temporary directory in the build
    export RELEASE_DIR="$PWD/dist"
    echo "Building Expo web app to $RELEASE_DIR..."
    
    # Build the Expo web app
    npx expo export --platform web --output-dir "$RELEASE_DIR"
    
    echo "Build completed. Contents of $RELEASE_DIR:"
    ls -la $RELEASE_DIR
  '';
  
  installPhase = ''
    # Copy the Expo web output to the Nix output directory
    mkdir -p $out
    echo "Installing to $out"
    cp -r $RELEASE_DIR/* $out/
    echo "Installation complete. Contents of $out:"
    ls -la $out
  '';
} 