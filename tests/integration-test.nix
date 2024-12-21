{ testers }:
testers.runNixOSTest {
  name = "integration-test";
  nodes = {
    client = ./machines/client.nix;
    produceAttrPaths = ./machines/produce-attr-paths.nix;
    produceDerivations = ./machines/produce-derivations.nix;
  };
  # TODO: Handle derivation eval failures.
  testScript = ''
    import json
    start_all()

    with subtest("wait for network availability"):
      client.wait_for_unit("systemd-networkd")
      produceAttrPaths.wait_for_unit("systemd-networkd")
      produceDerivations.wait_for_unit("systemd-networkd")

    with subtest("check produce-attr-paths service"):
      produceAttrPaths.systemctl("status produce-attr-paths")
      produceAttrPaths.wait_for_open_port(3000)

    with subtest("check query-attr-paths"):
      attr_paths = json.loads(client.succeed("query-attr-paths 'legacyPackages.x86_64-linux.cudaPackages_12'"))
  '';
  # with subtest("check produce-derivations service"):
  #   produceDerivations.systemctl("status produce-derivations")
  #   produceDerivations.wait_for_open_port(3001)

  # with subtest("check query-derivations"):
  #   for attr_path in attr_paths:
  #     # TODO: String escaping
  #     client.succeed("query-derivations " + attr_path)
}
