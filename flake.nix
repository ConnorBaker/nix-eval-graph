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

      flake.overlays.default = import ./overlay.nix;

      perSystem =
        {
          config,
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
            name = "cargo";
            package = [
              pkgs.cargo
            ];
          };

          legacyPackages = pkgs;

          packages = { };

          pre-commit.settings.hooks = {
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

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              # Markdown, YAML
              # JSON is not formatted; it should not be modified because it is either vendored from NVIDIA or
              # produced by a script.
              prettier = {
                enable = true;
                includes = [
                  "*.md"
                  "*.yaml"
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
              rustfmt.enable = true;

              # Shell
              shfmt.enable = true;
            };
          };
        };
    };
}
