{
  lib,
  produce-attr-paths,
  rustPlatform,
}:
let
  inherit (lib) licenses maintainers;
  inherit (lib.fileset) toSource unions;
  inherit (lib.trivial) importTOML;

  cargoTOML = importTOML ./Cargo.toml;

  projectSources = unions [
    # Lock file
    finalAttrs.cargoLock.lockFile

    # Project-specific files
    ./Cargo.toml
    ./LICENSE
    ./src

    # Dependencies
    produce-attr-paths.passthru.projectSources
  ];

  finalAttrs = {
    __structuredAttrs = true;
    strictDeps = true;

    pname = cargoTOML.package.name;
    inherit (cargoTOML.package) version;

    src = toSource {
      root = ../..;
      fileset = projectSources;
    };

    buildAndTestSubdir = "rust-packages/produce-derivations";

    cargoLock.lockFile = ../../Cargo.lock;

    passthru = {
      inherit projectSources;
    };

    meta = {
      description = "Consumes a flake reference and attribute path and produces the set of derivations required to build it";
      homepage = "https://github.com/ConnorBaker/nix-eval-graph/tree/main/rust-packages/produce-derivations";
      license = licenses.mit;
      mainProgram = "produce-derivations";
      maintainers = with maintainers; [
        connorbaker
        djacu
      ];
    };
  };
in
rustPlatform.buildRustPackage finalAttrs
