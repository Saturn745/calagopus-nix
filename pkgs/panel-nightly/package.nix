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
  version = "637ae4e6ff020b22e10ce3d6f9e9702b52ccb2a0";
  src = fetchFromGitHub {
    owner = "calagopus";
    repo = "panel";
    rev = "${version}";
    sha256 = "sha256-BL2knLIGE0HTHuHebsLNio008IcJhoASxkzxwsYxWyk=";
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
      fetcherVersion = 3;
      hash = "sha256-Y6xKhYMBP6REw7OGsM/VQz3BZ5Fa13SpiRYmM/Buk3s=";
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

    cargoLock = {
      lockFile = src + "/Cargo.lock";
      outputHashes = {
        "compact_str-0.9.0" = "sha256-kUeH/N9X6XqKaI9ZZgP9HrYxBq4OofWqBANvCnQBBPg=";
        "garde-0.22.1" = "sha256-xV14dWRbm/Hhv2OPnaO98/lOXqttUFnVsSBhbRs1AsY=";
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
    };
  })
