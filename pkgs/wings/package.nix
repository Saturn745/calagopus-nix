{
  lib,
  fetchFromGitHub,
  rustPlatform,
  autoPatchelfHook,
  stdenv,
  perl,
  pkg-config,
  cmake,
  openssl,
  libssh2,
  zlib,
}: let
  # Latest stable release: https://github.com/calagopus/wings/releases
  version = "1.1.3";
  src = fetchFromGitHub {
    owner = "calagopus";
    repo = "wings";
    rev = "release-${version}";
    sha256 = "sha256-q8w91XEhpLa0c1Ut2DzwOBK04ENCHBOaWG3zfbJphY0=";
  };
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "calagopus-wings";
    inherit version src;

    cargoHash = "sha256-ppi9UKwo2rnwmojFkRcDasnpSXh/c1Vi2oqIt4/e53E=";

    nativeBuildInputs = [
      autoPatchelfHook
      perl
      pkg-config
      cmake
    ];

    buildInputs = [
      stdenv.cc.cc.lib
      openssl
      libssh2
      zlib
    ];

    # Build only the application binary (wings-rs), not the workspace defaults
    cargoBuildFlags = ["-p" "wings-rs"];

    env = {
      CARGO_GIT_BRANCH = "unknown";
      CARGO_GIT_COMMIT = "unknown";
    };

    meta = {
      description = "Pterodactyl Wings alternative written in Rust — faster, more features, more maintainable";
      homepage = "https://calagopus.com";
      license = lib.licenses.mit;
      maintainers = [];
      mainProgram = "wings-rs";
      platforms = lib.platforms.linux;
    };
  })
