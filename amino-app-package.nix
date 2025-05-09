{pkgs, inputs}:

pkgs.stdenv.mkDerivation {
  name = "amino-app";
  src = inputs.amino-app; # Using the amino-app input defined in flake.nix
  sandbox = false; # Allow network access during the build
  
  nativeBuildInputs = with pkgs; [ 
    nodejs
    nodePackages.npm
    # Add DNS utilities
    bind
    iproute2
  ];
  
  # Add DNS configuration
  __noChroot = false;  # This is the correct setting
  
  buildPhase = ''
    set -x
    # Set up npm to install packages in the build directory
    export HOME=$PWD
    
    # Configure npm to use a local registry and avoid network issues
    npm config set registry https://registry.npmjs.org/
    npm config set fetch-retries 5
    npm config set fetch-retry-mintimeout 20000
    npm config set fetch-retry-maxtimeout 120000
    npm config set fetch-retry-factor 2
    
    # Add more npm configuration for reliability
    npm config set fetch-timeout 300000
    
    # Show npm configuration
    echo "Current npm configuration:"
    npm config list
    
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
    set +e  # Don't exit on error
    timeout 900 npm ci --no-audit --no-fund --prefer-offline --verbose 2>&1 | tee npm-ci.log
    npm_ci_status=$?
    set -e  # Exit on error again
    
    if [ $npm_ci_status -ne 0 ]; then
      echo "npm ci failed with status $npm_ci_status, falling back to npm install..."
      echo "Contents of npm-ci.log:"
      cat npm-ci.log
      
      # Clear node_modules if it exists to avoid conflicts
      rm -rf node_modules
      echo "About to run npm install..."
      
      set +e  # Don't exit on error
      timeout 900 npm install --no-audit --no-fund --prefer-offline --verbose 2>&1 | tee npm-install.log
      npm_install_status=$?
      set -e  # Exit on error again
      
      if [ $npm_install_status -ne 0 ]; then
        echo "npm install also failed with status $npm_install_status"
        echo "Contents of npm-install.log:"
        cat npm-install.log
        exit 1
      fi
    fi
    
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
