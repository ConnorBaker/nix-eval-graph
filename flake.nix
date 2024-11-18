{
  inputs = {
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };
    nixpkgs.url = "github:nixos/nixpkgs";
    git-hooks-nix = {
      inputs = {
        nixpkgs-stable.follows = "nixpkgs";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:cachix/git-hooks.nix";
    };
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks-nix.flakeModule
      ];

      flake.overlays = import ./overlays inputs;

      perSystem =
        {
          config,
          lib,
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.self.overlays.default ];
          };

          devShells.default = pkgs.mkShell {
            name = "rust-devShell";
            packages =
              (with pkgs; [
                cargo
                clippy
                rust-analyzer
                rustc
                rustfmt
                rustPlatform.rustLibSrc
              ])
              ++ config.pre-commit.settings.enabledPackages;
            # So that rust-analyzer can find the source code of the standard library
            env.RUST_SRC_PATH = pkgs.rustPlatform.rustLibSrc.outPath;
            # Install pre-commit hooks
            shellHook = config.pre-commit.installationScript;
          };

          legacyPackages = pkgs;

          packages = {
            inherit (pkgs) produce-attr-paths produce-derivations;
          };

          # NOTE: Cargo is run offline and does not have access to our dependencies, so we need
          # to make an environment which has them present.
          # https://github.com/cachix/git-hooks.nix/pull/396/files
          checks = {
            integration-test = pkgs.callPackage ./tests/integration-test.nix { };
            pre-commit =
              let
                drv = config.pre-commit.settings.run;
                env = pkgs.stdenv.mkDerivation {
                  __structuredAttrs = true;
                  strictDeps = true;
                  name = "pre-commit-run";
                  src = config.pre-commit.settings.rootSrc;
                  nativeBuildInputs = [
                    pkgs.git
                    pkgs.rustPlatform.cargoSetupHook
                  ] ++ config.pre-commit.settings.enabledPackages;
                  cargoDeps = pkgs.rustPlatform.importCargoLock {
                    lockFile = ./Cargo.lock;
                  };
                  buildPhase = drv.buildCommand;
                };
              in
              lib.mkForce env;
          };

          pre-commit.settings = {
            settings.rust.cargoManifestPath = "Cargo.toml";
            hooks = {
              # Misc checks
              check-executables-have-shebangs.enable = true;
              check-merge-conflicts.enable = true;
              check-shebang-scripts-are-executable.enable = true;
              check-symlinks.enable = true;
              check-toml.enable = true;
              mixed-line-endings.enable = true;

              # Nix checks
              deadnix.enable = true;
              nil.enable = true;
              statix.enable = true;

              # Rust
              clippy = {
                enable = true;
                require_serial = true; # Don't parallelize
                settings.allFeatures = true;
              };
            };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            settings.global.excludes = [
              "LICENSE"
              "**/LICENSE"
            ];
            programs = {
              prettier = {
                enable = true;
                includes = [
                  "*.md"
                ];
                settings = {
                  embeddedLanguageFormatting = "auto";
                  printWidth = 120;
                  tabWidth = 2;
                };
              };

              # Nix
              nixfmt.enable = true;

              # Rust
              rustfmt = {
                # TODO: Keep in sync with the Cargo.toml files in rust-packages/*.
                edition = "2021";
                enable = true;
              };

              # TOML
              taplo.enable = true;
              toml-sort = {
                all = true;
                enable = true;
              };
            };
          };
        };
    };
}
