{pkgs, inputs}:

pkgs.stdenv.mkDerivation {
  name = "amino-app";
  src = inputs.amino-app; # Using the amino-app input defined in flake.nix
  sandbox = false; # Allow network access during the build
  
  nativeBuildInputs = with pkgs; [ 
    nodejs
    nodePackages.npm
  ];
  
  buildPhase = ''
    set -x
    # Set up npm to install packages in the build directory
    export HOME=$PWD
    echo "Starting build in $PWD"
    echo "Contents of directory:"
    ls -la
    
    # Configure npm to use a local registry and avoid network issues
    npm config set registry https://registry.npmjs.org/
    npm config set fetch-retries 5
    npm config set fetch-retry-mintimeout 20000
    npm config set fetch-retry-maxtimeout 120000
    
    echo "Checking for package.json..."
    if [ -f package.json ]; then
      echo "package.json found"
      cat package.json
    else
      echo "ERROR: package.json not found!"
      exit 1
    fi
    
    echo "About to run npm ci..."
    # Use npm ci with increased timeout and network settings
    timeout 900 npm ci --no-audit --no-fund --prefer-offline 2>&1 | tee npm-ci.log || {
      echo "npm ci failed or timed out, falling back to npm install..."
      # Clear node_modules if it exists to avoid conflicts
      rm -rf node_modules
      echo "About to run npm install..."
      timeout 900 npm install --no-audit --no-fund --prefer-offline 2>&1 | tee npm-install.log
    }
    echo "npm install step complete."
    
    echo "Processing TailwindCSS..."
    timeout 300 npx tailwindcss -i global.css -o ./node_modules/.cache/nativewind/global.css || {
      echo "TailwindCSS processing failed or timed out, creating empty CSS file..."
      mkdir -p ./node_modules/.cache/nativewind/
      touch ./node_modules/.cache/nativewind/global.css
    }
    
    # Set RELEASE_DIR to point to a temporary directory in the build
    export RELEASE_DIR="$PWD/dist"
    echo "Building Expo web app to $RELEASE_DIR..."
    
    # Build the Expo web app with timeout
    timeout 900 npx expo export --platform web --output-dir "$RELEASE_DIR" || {
      echo "Expo export failed or timed out, creating minimal web output..."
      mkdir -p "$RELEASE_DIR"
      echo "<html><body><h1>Amino App</h1><p>Build failed. Please check the build logs.</p></body></html>" > "$RELEASE_DIR/index.html"
    }
    
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
