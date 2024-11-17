{
  lib,
  rustPlatform,
}:
let
  inherit (lib) licenses maintainers;
  inherit (lib.fileset) toSource unions;

  finalAttrs = {
    __structuredAttrs = true;
    strictDeps = true;

    pname = "produce-attr-paths";
    version = "0.1.0";

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
