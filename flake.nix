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
        let
          inherit (lib.filesystem) packagesFromDirectoryRecursive;
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.self.overlays.default ];
          };

          devShells =
            packagesFromDirectoryRecursive {
              inherit (pkgs) callPackage;
              directory = ./devShells;
            }
            // {
              default = config.devShells.rust-devShell;
            };

          legacyPackages = pkgs;

          packages = {
            inherit (pkgs) produce-attr-paths produce-derivations;
          };

          pre-commit.settings = {
            settings.rust.cargoManifestPath = "Cargo.toml";
            hooks = {
              # Formatter checks
              treefmt = {
                enable = true;
                package = config.treefmt.build.wrapper;
              };

              # Nix checks
              deadnix.enable = true;
              nil.enable = true;
              statix.enable = true;

              # Rust
              clippy.enable = true;

              # Shell
              shellcheck.enable = true;
            };
          };

          treefmt = {
            flakeCheck = false; # Run by pre-commit
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
                excludes = [ "*.json" ];
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
                enable = true;
                # TODO: Keep in sync with the Cargo.toml files in rust-packages/*.
                edition = "2021";
              };

              # Shell
              shfmt.enable = true;

              # TOML
              taplo.enable = true;
              toml-sort.enable = true;
            };
          };
        };
    };
}
