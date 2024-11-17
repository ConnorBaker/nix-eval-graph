inputs:
let
  # inherits
  inherit (inputs.nixpkgs.lib.fixedPoints) composeManyExtensions;

  # all local rust packages an overlay
  rustPackages = import ./rust-packages.nix;

  # all local packages in a single overlay
  default = composeManyExtensions [ rustPackages ];
in
{
  inherit
    rustPackages
    default
    ;
}
