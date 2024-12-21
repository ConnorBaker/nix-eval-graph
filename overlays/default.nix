inputs:
let
  # inherits
  inherit (inputs.nixpkgs.lib.fixedPoints) composeManyExtensions;

  # all local rust packages an overlay
  nixNoGC = final: _: {
    nix-no-gc = inputs.nix.hydraJobs.buildNoGc.nix-everything.${final.stdenv.hostPlatform.system};
  };
  rustPackages = import ./rust-packages.nix;

  # all local packages in a single overlay
  default = composeManyExtensions [
    nixNoGC
    rustPackages
  ];
in
{
  inherit
    nixNoGC
    rustPackages
    default
    ;
}
