{ lib, ... }:
{
  imports = [
    ../../../nixosModules/headless.nix
    ../../../nixosModules/networking.nix
    ../../../nixosModules/nix.nix
    ../../../nixosModules/virtualisation.nix
    ../../../nixosModules/zram.nix
  ];
  networking.useNetworkd = lib.mkForce true;
  systemd = {
    network = {
      # Disable config for the client and produce-attr-paths
      links."10-eth1".enable = false;
      # systemd-networkd will load the first network unit file
      # that matches, ordered lexiographically by filename.
      # /etc/systemd/network/{40-eth1,99-main}.network already
      # exists. This network unit must be loaded for the test,
      # however, hence why this network is named such.
      networks = {
        "01-eth1" = {
          name = "eth1";
          address = [ "10.0.0.1/24" ];
          networkConfig.DHCPServer = true;
          dhcpServerStaticLeases = [
            # client
            {
              MACAddress = "02:de:ad:be:ef:03";
              Address = "10.0.0.3";
            }
            # produce-attr-paths
            {
              MACAddress = "02:de:ad:be:ef:04";
              Address = "10.0.0.4";
            }
          ];
        };
        # Disable config for the client and produce-attr-paths
        "40-eth1".enable = false;
      };
    };
    services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
  };
}
