{ testers }:
testers.runNixOSTest {
  name = "produce-attr-paths-cudaPackages_12-test";
  nodes = {
    client = ./machines/client.nix;
    produceAttrPaths = ./machines/produce-attr-paths.nix;
  };
  testScript = ''
    start_all()

    with subtest("wait for network availability"):
      client.wait_for_unit("systemd-networkd")
      produceAttrPaths.wait_for_unit("systemd-networkd")

    with subtest("check produce-attr-paths service"):
      produceAttrPaths.systemctl("status produce-attr-paths")
      produceAttrPaths.wait_for_open_port(3000)

    with subtest("check query-attr-paths"):
      client.succeed("query-attr-paths 'legacyPackages.x86_64-linux.cudaPackages_12'")
  '';
}
