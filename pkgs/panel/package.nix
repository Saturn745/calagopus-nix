{
  lib,
  stdenv,
  nodejs,
  pnpmConfigHook,
  pnpm,
  fetchPnpmDeps,
  fetchFromGitHub,
  rustPlatform,
  perl,
  openssl,
}: let
  tag = "release-1.0.0-pre.2";
  version = "1.0.0-pre.2";
  src = fetchFromGitHub {
    owner = "calagopus";
    repo = "panel";
    rev = "${tag}";
    sha256 = "sha256-/12TvW8SYRn2cYyNrgz/HJGX+3OJMaW+6UQlObgTjgM=";
  };
  frontend = stdenv.mkDerivation (finalAttrs: {
    pname = "calagopus-panel-frontend";
    version = "v${version}";

    src = src + "/frontend";

    nativeBuildInputs = [
      nodejs
      pnpmConfigHook
      pnpm
    ];

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      fetcherVersion = 3;
      hash = "sha256-lNl/29ba5QmYk2KOZIWcXPB8RmuwAlugCpArLrIsodI=";
    };

    buildPhase = ''
      runHook preBuild
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
      cp -r dist/ $out
    '';
  });
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "calagopus-panel";
    version = "v${version}";
    inherit src;

    cargoLock = {
      lockFile = src + "/Cargo.lock";
      outputHashes = {
        "compact_str-0.9.0" = "sha256-5Bohbr/wHr0+KJroZUhIf2hdKVUYHX971wykTX52R+w=";
      };
    };

    nativeBuildInputs = [
      perl
      openssl
    ];
    env = {
      CARGO_GIT_BRANCH = "unknown";
      CARGO_GIT_COMMIT = "unknown";
    };

    preBuild = ''
      # Copy the frontend source code to the build directory
      cp -r ${frontend} ./frontend/dist/
    '';

    passthru = {
      inherit frontend;
    };

    meta = {
      description = "Game server management - made simple";
      homepage = "https://calagopus.com/";
      license = lib.licenses.mit;
      maintainers = [];
      mainProgram = "panel-rs";
    };
  })
