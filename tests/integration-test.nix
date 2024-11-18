{
  testers,
}:
let

  commonModule = {
    virtualisation = {
      cores = 4;
      graphics = false;
      memorySize = 4096;
      # TODO(@connorbaker): Consider using useNixStoreImage if it boosts performance?
    };
    # TODO(@connorbaker): Why can't I use CURL in the clientMachine against the produceAttrPathsMachine?
    # Accessing directly by IP address works (in the case below, localhost), but not by hostname!
    networking.firewall.enable = false;
  };
in
testers.runNixOSTest {
  name = "integration-test";
  nodes = {
    clientMachine =
      { pkgs, ... }:
      let
        queryAttrPaths = pkgs.writeShellApplication {
          name = "query-attr-paths";
          runtimeInputs = [ pkgs.curl ];
          text = ''
            curl -L \
              -X GET 'http://produceAttrPathsMachine:3000/produce-attr-paths' \
              -H 'Content-Type: application/json' \
              -d '{
                    "flakeRef": "github:ConnorBaker/cuda-packages/8cb28e23b8c7cee612fb68d86a12b263841df109",
                    "attrPath": "legacyPackages.x86_64-linux.pkgsCuda.sm_89.cudaPackages_12"
                  }'
          '';
        };
      in
      {
        imports = [ commonModule ];
        environment.systemPackages = [ queryAttrPaths ];
        system.stateVersion = "24.05";
      };
    produceAttrPathsMachine =
      { lib, pkgs, ... }:
      let
        queryAttrPaths = pkgs.writeShellApplication {
          name = "query-attr-paths";
          runtimeInputs = [ pkgs.curl ];
          text = ''
            curl -L \
              -X GET 'http://produceAttrPathsMachine:3000/produce-attr-paths' \
              -H 'Content-Type: application/json' \
              -d '{
                    "flakeRef": "github:ConnorBaker/cuda-packages/8cb28e23b8c7cee612fb68d86a12b263841df109",
                    "attrPath": "legacyPackages.x86_64-linux.pkgsCuda.sm_89.cudaPackages_12"
                  }'
          '';
        };
      in
      {
        imports = [ commonModule ];
        networking.firewall.allowedUDPPorts = [
          80
          443
          3000
        ];
        networking.firewall.allowedTCPPorts = [
          80
          443
          3000
        ];
        environment.systemPackages = [
          pkgs.produce-attr-paths
          queryAttrPaths
        ];
        system.stateVersion = "24.05";
        systemd.services.produce-attr-paths = {
          enable = true;
          description = "A service that produces attribute paths";
          unitConfig.Type = "simple";
          serviceConfig.ExecStart = lib.getExe pkgs.produce-attr-paths;
          requires = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
        };
      };
  };
  testScript =
    # { nodes, ... }:
    ''
      start_all()

      # Wait for network and produce-attr-paths to be ready
      produceAttrPathsMachine.systemctl("start network-online.target")
      produceAttrPathsMachine.wait_for_unit("network-online.target")
      produceAttrPathsMachine.wait_for_unit("produce-attr-paths")
      produceAttrPathsMachine.wait_for_open_port(3000)
      produceAttrPathsMachine.wait_until_succeeds("curl -L -vvvvv 'http://127.0.0.1:3000/produce-attr-paths'")
    '';
  # clientMachine.systemctl("start network-online.target")
  # clientMachine.wait_for_unit("network-online.target")
  # clientMachine.wait_until_succeeds("curl -L -vvvvv 'http://produceAttrPathsMachine:3000/produce-attr-paths'")
  # clientMachine.wait_for_unit("network-online.target")
  # clientMachine.succeed("which query-attr-paths")
  # clientMachine.succeed("query-attr-paths")
}
