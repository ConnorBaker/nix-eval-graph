{
  testers,
}:
testers.runNixOSTest {
  name = "integration-test";
  nodes = {
    router = ./machines/router.nix;
    client = ./machines/client.nix;
    produceAttrPaths = ./machines/produce-attr-paths.nix;
  };
  testScript =
    ''
      start_all()
    ''
    # Wait for network availability
    + ''
      with subtest("check router network configuration"):
        router.wait_for_unit("systemd-networkd-wait-online.service")
        client.wait_for_unit("systemd-networkd-wait-online.service")
        produceAttrPaths.wait_for_unit("systemd-networkd-wait-online.service")
    ''
    # Check that the produce-attr-paths service is running
    + ''
      with subtest("check produce-attr-paths service"):
        produceAttrPaths.systemctl("status produce-attr-paths")
        produceAttrPaths.wait_for_open_port(3000)

      with subtest("check query-attr-paths"):
        client.succeed("query-attr-paths")
    '';
}
