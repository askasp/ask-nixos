{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  src ? null,
  ...
}:

rustPlatform.buildRustPackage {
  pname = "amino-api";
  version = "0.1.0"; # Replace with actual version when known

  src = if src != null then src else fetchFromGitHub {
    owner = "AminoNordics";
    repo = "amino_api";
    # Replace these with actual values when you have access to the repo
    rev = "main"; # Or specific commit/tag
    hash = lib.fakeHash; # Will need to be updated when you have access
  };

  # To get the cargoHash:
  # 1. First, uncomment this line to make the build fail and show expected hash
  # 2. It will print the expected hash in the error message
  # 3. Copy that hash back into this field
  cargoHash = null; # Comment this line later

  # We use fetchCargoTarball to avoid needing the cargoHash
  # This helps during initial setup
  # Once you get the proper cargoHash from the error, 
  # comment these two lines and use cargoHash instead
  cargoLock.lockFile = "${src}/Cargo.lock";
  fetchCargoDeps = null;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ];

  # Uncomment if the package has any tests you want to run
  # doCheck = true;

  meta = with lib; {
    description = "Amino API Rust service";
    homepage = "https://github.com/AminoNordics/amino_api";
    license = licenses.unfree; # Update with actual license if known
    platforms = platforms.unix;
  };
} 