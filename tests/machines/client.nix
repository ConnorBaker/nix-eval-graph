{ pkgs, ... }:
let
  testFlakeRef = "github:NixOS/nixpkgs/7a56cc79c6514a5a6ea283745d6f1bf0f8c8166f";
  testFlake = builtins.getFlake testFlakeRef;

  queryAttrPaths = pkgs.writeShellApplication {
    name = "query-attr-paths";
    runtimeInputs = [
      pkgs.curl
      testFlake.outPath
    ];
    text = ''
      if (( $# != 1 )); then
        echo "Exactly one argument should be passed to query-derivations" >&2
        exit 1
      fi
      curl \
        -Ls \
        -X GET 'http://produceAttrPaths:3000/produce-attr-paths' \
        -H 'Content-Type: application/json' \
        -d "{
              \"flakeRef\": \"path:${testFlake.outPath}?narHash=${testFlake.sourceInfo.narHash}\",
              \"attrPath\": \"$1\"
            }"
    '';
  };

  queryDerivations = pkgs.writeShellApplication {
    name = "query-derivations";
    runtimeInputs = [
      pkgs.curl
      testFlake.outPath
    ];
    # TODO: Better way to pass JSON to curl?
    text = ''
      if (( $# != 1 )); then
        echo "Exactly one argument should be passed to query-derivations" >&2
        exit 1
      fi
      curl \
        -Ls \
        -X GET 'http://produceDerivations:3001/produce-derivations' \
        -H 'Content-Type: application/json' \
        -d "{
              \"flakeRef\": \"path:${testFlake.outPath}?narHash=${testFlake.sourceInfo.narHash}\",
              \"attrPath\": \"$1\"
            }"
    '';
  };
in
{
  imports = [
    ../../nixosModules/headless.nix
    ../../nixosModules/networking.nix
    ../../nixosModules/nix.nix
    ../../nixosModules/virtualisation.nix
    ../../nixosModules/zram.nix
  ];
  environment.systemPackages = [
    queryAttrPaths
    queryDerivations
  ];
  system.stateVersion = "24.05";
}
