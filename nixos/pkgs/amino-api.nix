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
  version = "0.1.0";

  src = if src != null then src else fetchFromGitHub {
    owner = "AminoNordics";
    repo = "amino_api";
    rev = "main";
    hash = lib.fakeHash;
  };

  # This will intentionally fail the first time with the correct hash
  # Just copy the hash from the error message and put it here
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "ask-cqrs-0.1.0" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with actual hash
    };
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ];

  meta = with lib; {
    description = "Amino API Rust service";
    homepage = "https://github.com/AminoNordics/amino_api";
    license = licenses.unfree;
    platforms = platforms.unix;
  };
} 