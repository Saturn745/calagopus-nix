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
  rev = "8057167c67f7af426a4a3181dbe5ca6ea25494bf";
  version = "release-1.1.2-unstable-2026-08-09";
  src = fetchFromGitHub {
    owner = "calagopus";
    repo = "wings";
    inherit rev;
    sha256 = "sha256-q8w91XEhpLa0c1Ut2DzwOBK04ENCHBOaWG3zfbJphY0=";
  };
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "calagopus-wings-nightly";
    inherit version src;

    cargoHash = "sha256-ppi9UKwo2rnwmojFkRcDasnpSXh/c1Vi2oqIt4/e53E=";

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
