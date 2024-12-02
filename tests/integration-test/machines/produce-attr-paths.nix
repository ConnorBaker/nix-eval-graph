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
    ../../../nixosModules/headless.nix
    ../../../nixosModules/networking.nix
    ../../../nixosModules/nix.nix
    ../../../nixosModules/virtualisation.nix
    ../../../nixosModules/zram.nix
  ];
  environment.systemPackages = [ pkgs.produce-attr-paths ];
  systemd = {
    network.links."10-eth1".linkConfig.MACAddress = "02:de:ad:be:ef:04";
    services.produce-attr-paths = {
      enable = true;
      description = "A service that produces attribute paths";
      environment.RUST_BACKTRACE = "1";
      unitConfig.Type = "simple";
      serviceConfig.ExecStart = lib.getExe pkgs.produce-attr-paths;
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
  virtualisation = {
    cores = mkForce 4;
    memorySize = mkForce 8192;
  };
}
