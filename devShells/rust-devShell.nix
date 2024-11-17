{
  cargo,
  clippy,
  mkShell,
  rust-analyzer,
  rustc,
  rustPlatform,
}:
mkShell {
  name = "rust-devShell";
  packages = [
    cargo
    clippy
    rust-analyzer
    rustc
    rustPlatform.rustLibSrc
  ];
  # So that rust-analyzer can find the source code of the standard library
  env.RUST_SRC_PATH = rustPlatform.rustLibSrc.outPath;
}
