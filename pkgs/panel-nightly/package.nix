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
  version = "cbef5326c2928c60fde53a1e20dc8be9417347b9";
  src = fetchFromGitHub {
    owner = "calagopus";
    repo = "panel";
    rev = "${version}";
    sha256 = "sha256-jiSP2wcfV4KfPsHuXqgz6ua04Euo6GWCTpsau6mQz4o=";
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
