{
  lib,
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

    buildAndTestSubdir = "rust-packages/produce-attr-paths";

    cargoLock.lockFile = ../../Cargo.lock;

    passthru = {
      inherit projectSources;
    };

    meta = {
      description = "Produces a list of attribute paths under a given attribute path in a flake reference";
      homepage = "https://github.com/ConnorBaker/nix-eval-graph/tree/main/rust-packages/produce-attr-paths";
      license = licenses.mit;
      maintainers = with maintainers; [
        connorbaker
        djacu
      ];
    };
  };
in
rustPlatform.buildRustPackage finalAttrs
