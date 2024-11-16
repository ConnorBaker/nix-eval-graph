inputs:
let
  # inherits
  inherit (inputs.nixpkgs.lib.fixedPoints)
    composeManyExtensions
    ;
  inherit (inputs.nixpkgs.lib.filesystem)
    packagesFromDirectoryRecursive
    ;

  # all local rust packages an overlay
  rustPackages =
    final: prev:
    packagesFromDirectoryRecursive {
      callPackage = final.callPackage;
      directory = ../rust-packages;
    };

  # all local packages in a single overlay
  default = composeManyExtensions [ rustPackages ];
in
{
  inherit
    rustPackages
    default
    ;
}
