final: prev:
let
  inherit (prev.lib.filesystem) packagesFromDirectoryRecursive;
in
packagesFromDirectoryRecursive {
  inherit (final) callPackage;
  directory = ../rust-packages;
}
