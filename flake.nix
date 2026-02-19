{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    supportedSystems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    forAllSystems = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {
            inherit system;
            overlays = [inputs.self.overlays.default];
          };
        });
  in {
    overlays.default = final: prev: {
      rustToolchain = with inputs.fenix.packages.${prev.stdenv.hostPlatform.system};
        combine (
          with stable; [clippy rustc cargo rustfmt rust-src]
        );
    };

    packages = forAllSystems ({pkgs}: let
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
    });
  };
}
