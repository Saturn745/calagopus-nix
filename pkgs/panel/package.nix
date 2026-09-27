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
  version = "1.2.3";
  src = fetchFromGitHub {
    owner = "calagopus";
    repo = "panel";
    rev = "release-${version}";
    sha256 = "sha256-Eoz4zyohO0YZnF5YE+cO2zK/jrwBkcdOuBm53OJacRQ=";
  };
  frontend = stdenv.mkDerivation (finalAttrs: {
    pname = "calagopus-panel-frontend";
    inherit version;

    src = src + "/frontend";

    nativeBuildInputs = [
      nodejs
      pnpmConfigHook
      pnpm
    ];

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      fetcherVersion = 4;
      hash = "sha256-LhFiaiharPUIuSYIM/BCvlDUDhh+aEnzXtviBqEY8Ks=";
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
    inherit version src;

    cargoHash = "sha256-PoAwOHtiJO91OAAmz7+LoklTluBXurLhnoSZ3Mn8xwA=";
    cargoBuildFlags = ["-p" "panel-rs"];
    cargoTestFlags = ["-p" "panel-rs"];

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
