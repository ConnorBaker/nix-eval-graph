{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkForce;
in
{
  imports = [
    ../../nixosModules/headless.nix
    ../../nixosModules/networking.nix
    ../../nixosModules/nix.nix
    ../../nixosModules/virtualisation.nix
    ../../nixosModules/zram.nix
  ];
  environment.systemPackages = [ pkgs.produce-derivations ];
  systemd.services.produce-derivations = {
    enable = true;
    description = "A service that produces derivations";
    environment.RUST_BACKTRACE = "1";
    unitConfig.Type = "simple";
    serviceConfig.ExecStart = lib.getExe pkgs.produce-derivations;
    requires = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };
  virtualisation = {
    cores = mkForce 2;
    memorySize = mkForce 8192;
  };
}
