{
  nix.settings = {
    accept-flake-config = true;
    allow-import-from-derivation = false;
    auto-allocate-uids = true;
    auto-optimise-store = false; # We wipe them frequently enough we don't need the performance hit.
    builders-use-substitutes = true;
    connect-timeout = 5; # Don't wait forever for a remote builder to respond.
    # Since these machines are builders for CUDA packages, makes sense to allow a larger buffer for curl because we
    # have lots of memory and will be downloading large tarballs.
    # NOTE: https://github.com/NixOS/nix/pull/11171
    download-buffer-size = 256 * 1024 * 1024; # 256 MB
    experimental-features = [
      "auto-allocate-uids"
      "cgroups"
      "flakes"
      "nix-command"
    ];
    fallback = true;
    fsync-metadata = false;
    http-connections = 256;
    log-lines = 100;
    max-jobs = 2;
    max-substitution-jobs = 64;
    # See: https://github.com/NixOS/nix/blob/1cd48008f0e31b0d48ad745b69256d881201e5ee/src/libstore/local-store.cc#L1172
    nar-buffer-size = 1 * 1024 * 1024 * 1024; # 1 GB
    require-drop-supplementary-groups = true;
    trusted-users = [
      "root"
      "@nixbld"
      "@wheel"
    ];
    use-cgroups = true;
    use-xdg-base-directories = true;
    warn-dirty = false;
  };
}
