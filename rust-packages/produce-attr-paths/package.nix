{
  lib,
  rustPlatform,
}:
let
  inherit (lib) licenses maintainers;
  inherit (lib.fileset) toSource unions;
  inherit (lib.trivial) importTOML;

  cargoTOML = importTOML ./Cargo.toml;

  finalAttrs = {
    __structuredAttrs = true;
    strictDeps = true;

    pname = cargoTOML.package.name;
    inherit (cargoTOML.package) version;

    src = toSource {
      root = ./.;
      fileset = unions [
        ./Cargo.lock
        ./Cargo.toml
        ./LICENSE
        ./src
      ];
    };

    cargoLock.lockFile = ./Cargo.lock;

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
