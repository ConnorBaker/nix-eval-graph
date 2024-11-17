{
  cargo,
  clippy,
  mkShell,
  rustc,
}:
mkShell {
  name = "rust-devShell";
  packages = [
    cargo
    clippy
    rustc
  ];
}
