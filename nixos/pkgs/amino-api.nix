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

  # When you have access to the repo:
  # To get the hash for the Cargo dependencies, run:
  # nix-prefetch-git https://github.com/AminoNordics/amino_api.git
  # Then, to get the cargoHash, first comment out the cargoHash line, then run:
  # nix-build -A amino-api 
  # The build will fail, but will tell you the expected cargoHash
  cargoHash = lib.fakeHash;

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