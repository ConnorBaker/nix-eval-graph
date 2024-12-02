{ pkgs, ... }:
let
  testFlakeRef = "github:NixOS/nixpkgs/7a56cc79c6514a5a6ea283745d6f1bf0f8c8166f";
  testFlake = builtins.getFlake testFlakeRef;
  testAttrPath = "legacyPackages.x86_64-linux.cudaPackages_12";
  queryAttrPaths = pkgs.writeShellApplication {
    name = "query-attr-paths";
    runtimeInputs = [
      pkgs.curl
      testFlake.outPath
    ];
    text = ''
      curl \
        -Lvvv \
        -X GET 'http://10.0.0.4:3000/produce-attr-paths' \
        -H 'Content-Type: application/json' \
        -d '{
              "flakeRef": "path:${testFlake.outPath}?narHash=${testFlake.sourceInfo.narHash}",
              "attrPath": "${testAttrPath}"
            }' \
        >&2
    '';
  };
in
{
  imports = [
    ../../../nixosModules/headless.nix
    ../../../nixosModules/networking.nix
    ../../../nixosModules/nix.nix
    ../../../nixosModules/virtualisation.nix
    ../../../nixosModules/zram.nix
  ];
  environment.systemPackages = [ queryAttrPaths ];
  system.stateVersion = "24.05";
  systemd.network.links."10-eth1".linkConfig.MACAddress = "02:de:ad:be:ef:03";
}
