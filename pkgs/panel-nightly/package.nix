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
  version = "39c84c839e52bc6d781e5573dd12737fa61a963d";
  src = fetchFromGitHub {
    owner = "calagopus";
    repo = "panel";
    rev = "${version}";
    sha256 = "sha256-SiArDY+bZ87w7do+/zS7Xkj1YK0fF5FlnHHhhsYQDaY=";
  };
  frontend = stdenv.mkDerivation (finalAttrs: {
    pname = "calagopus-panel-nightly-frontend";
    version = "v${version}";

    src = src + "/frontend";

    nativeBuildInputs = [
      nodejs
      pnpmConfigHook
      pnpm
    ];

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      fetcherVersion = 4;
      hash = "sha256-hf5jaUoG/G9BVn+5nGMfioHTzr9jz+9ot6R+L8/RUVc=";
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
    pname = "calagopus-panel-nightly";
    version = "v${version}";
    inherit src;

    cargoHash = "sha256-ZYNQhEy009VgOLTSnVDyWI39dWoHjSyBYDGmiJqY51Y=";
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
