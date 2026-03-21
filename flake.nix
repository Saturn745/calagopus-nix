{
  nixConfig = {
    extra-substituters = [ "https://calagopus-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "calagopus-nix.cachix.org-1:KnwFwKiw7rgY2depzwWWiPmLdW1gL5DfZKNTcUcB0oo="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, microvm, ...} @ inputs: let
    supportedSystems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    forAllSystems = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          inherit system;
          pkgs = import nixpkgs {
            inherit system;
            overlays = [inputs.self.overlays.default];
          };
        });
  in {
    nixosModules.default = ./modules/panel.nix;

    overlays.default = final: prev: let
      rustToolchain = with inputs.fenix.packages.${prev.stdenv.hostPlatform.system};
        combine (
          with stable; [clippy rustc cargo rustfmt rust-src]
        );
      rustPlatform = prev.makeRustPlatform {
        cargo = rustToolchain;
        rustc = rustToolchain;
      };
    in {
      inherit rustToolchain;
      panel = prev.callPackage ./pkgs/panel/package.nix { inherit rustPlatform; };
      panel-nightly = prev.callPackage ./pkgs/panel-nightly/package.nix { inherit rustPlatform; };
    };

    packages = forAllSystems ({pkgs, system, ...}: let
      rustPlatform = pkgs.makeRustPlatform {
        cargo = pkgs.rustToolchain;
        rustc = pkgs.rustToolchain;
      };
    in {
      panel = pkgs.callPackage ./pkgs/panel/package.nix {
        inherit rustPlatform;
      };
      panel-nightly = pkgs.callPackage ./pkgs/panel-nightly/package.nix {
        inherit rustPlatform;
      };
      microvm-test = let
        nixos = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            inputs.microvm.nixosModules.microvm
            inputs.self.nixosModules.default
            ({pkgs, ...}: {
              nixpkgs.overlays = [inputs.self.overlays.default];

              # interface type = "user" (SLIRP) is required for forwardPorts to work.
              # A real TAP interface would require a host bridge; SLIRP is sufficient for local testing.
              microvm = {
                hypervisor = "qemu";
                interfaces = [{
                  type = "user";
                  id = "panel-test";
                  mac = "02:00:00:00:00:01";
                }];
                forwardPorts = [{
                  from = "host";
                  host.port = 8000;
                  guest.port = 8000;
                }];
              };

              services.calagopus-panel = {
                enable = true;
                # pkgs here is the NixOS system's pkgs, not the outer forAllSystems pkgs.
                # Using it via the module argument avoids cross-system store path issues.
                environmentFile = pkgs.writeText "panel-test-env" ''
                  APP_ENCRYPTION_KEY=test-only-not-for-production
                '';
                database.createLocally = true;
                redis.createLocally = true;
              };

              system.stateVersion = "24.11";
            })
          ];
        };
      in nixos.config.microvm.declaredRunner;
    });
  };
}
