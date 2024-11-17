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
        ./Cargo.toml
        ./LICENSE
        ./src
      ];
    };

    cargoLock.lockFile = ../../Cargo.lock;

    # File must be writeable.
    postPatch = ''
      install -Dm644 ${../../Cargo.lock} Cargo.lock
    '';

    meta = {
      description = "Consumes a flake reference and attribute path and produces the set of derivations required to build it";
      homepage = "https://github.com/ConnorBaker/nix-eval-graph/tree/main/rust-packages/produce-derivations";
      license = licenses.mit;
      maintainers = with maintainers; [
        connorbaker
        djacu
      ];
    };
  };
in
rustPlatform.buildRustPackage finalAttrs
