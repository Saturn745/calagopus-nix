{
  lib,
  fetchFromGitHub,
  rustPlatform,
  perl,
  pkg-config,
  cmake,
  openssl,
  libssh2,
  zlib,
}: let
  # Latest main branch commit
  rev = "313dbf7ec7b16a8db97a42abf6a8fac65c5550fc";
  version = "release-1.1.3-unstable-2026-08-11";
  src = fetchFromGitHub {
    owner = "calagopus";
    repo = "wings";
    inherit rev;
    sha256 = "sha256-D4Tbu43zU+NfgkIEue0aS3/cNAQ7FqDC0xGZtGdQ5D0=";
  };
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "calagopus-wings-nightly";
    inherit version src;

    cargoHash = "sha256-M76nYlDw4IA+fAhz8dU46kgtlzFUYgUC/6CO3Fst0OM=";

    nativeBuildInputs = [
      perl
      pkg-config
      cmake
    ];

    buildInputs = [
      openssl
      libssh2
      zlib
    ];

    cargoBuildFlags = ["-p" "wings-rs"];

    env = {
      CARGO_GIT_BRANCH = "main";
      CARGO_GIT_COMMIT = rev;
    };

    meta = {
      description = "Pterodactyl Wings alternative written in Rust — faster, more features, more maintainable (nightly build)";
      homepage = "https://calagopus.com";
      license = lib.licenses.mit;
      maintainers = [];
      mainProgram = "wings-rs";
      platforms = lib.platforms.linux;
    };
  })
