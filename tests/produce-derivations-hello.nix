{ testers }:
testers.runNixOSTest {
  name = "produce-derivations-hello-test";
  nodes = {
    client = ./machines/client.nix;
    produceDerivations = ./machines/produce-derivations.nix;
  };
  testScript = ''
    start_all()

    with subtest("wait for network availability"):
      client.wait_for_unit("systemd-networkd")
      produceDerivations.wait_for_unit("systemd-networkd")

    with subtest("check produce-derivations service"):
      produceDerivations.systemctl("status produce-derivations")
      produceDerivations.wait_for_open_port(3001)

    with subtest("check query-derivations"):
      client.succeed("query-derivations 'legacyPackages.x86_64-linux.hello'")
  '';
}
