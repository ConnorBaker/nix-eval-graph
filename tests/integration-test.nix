{
  testers,
}:
let
  commonModules = [
    ../nixosModules/headless.nix
    ../nixosModules/networking.nix
    ../nixosModules/nix.nix
    ../nixosModules/virtualisation.nix
    ../nixosModules/zram.nix
  ];

  # Includes the narHash to avoid downloading the same nar twice
  testFlakeRef = "github:ConnorBaker/cuda-packages/8cb28e23b8c7cee612fb68d86a12b263841df109";
in
testers.runNixOSTest {
  name = "integration-test";
  nodes = {
    # clientMachine =
    #   { pkgs, ... }:
    #   let
    #     queryAttrPaths = pkgs.writeShellApplication {
    #       name = "query-attr-paths";
    #       runtimeInputs = [ pkgs.curl pkgs.fakeNss ];
    #       text = ''
    #         curl -L \
    #           -X GET 'http://produceAttrPathsMachine:3000/produce-attr-paths' \
    #           -H 'Content-Type: application/json' \
    #           -d '{
    #                 "flakeRef": "github:ConnorBaker/cuda-packages/8cb28e23b8c7cee612fb68d86a12b263841df109",
    #                 "attrPath": "legacyPackages.x86_64-linux.pkgsCuda.sm_89.cudaPackages_12"
    #               }'
    #       '';
    #     };
    #   in
    #   {
    #     imports = [ commonModule ];
    #     environment.systemPackages = [ queryAttrPaths ];
    #     system.stateVersion = "24.05";
    #   };
    produceAttrPathsMachine =
      {
        lib,
        pkgs,
        ...
      }:
      let
        queryAttrPaths = pkgs.writeShellApplication {
          name = "query-attr-paths";
          runtimeInputs = [
            pkgs.curl
          ];
          text = ''
            curl -L \
              -X GET 'http://produceAttrPathsMachine:3000/produce-attr-paths' \
              -H 'Content-Type: application/json' \
              -d '{
                    "flakeRef": "${testFlakeRef}",
                    "attrPath": "legacyPackages.x86_64-linux.pkgsCuda.sm_89.cudaPackages_12"
                  }'
          '';
        };
      in
      {
        imports = commonModules;
        environment.systemPackages = [
          pkgs.produce-attr-paths
          queryAttrPaths
        ];
        systemd.services.produce-attr-paths = {
          enable = true;
          description = "A service that produces attribute paths";
          environment.RUST_BACKTRACE = "1";
          unitConfig.Type = "simple";
          serviceConfig.ExecStart = lib.getExe pkgs.produce-attr-paths;
          requires = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
        };
      };
    # TODO:
    # > produceAttrPathsMachine #   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0[   11.496941] produce-attr-paths[669]: 2024-11-21T07:45:46.526859Z DEBUG http_request{method=GET matched_path="/produce-attr-paths"}: tower_http::trace::on_request: started processing request
    # > produceAttrPathsMachine # [   11.497395] produce-attr-paths[669]: 2024-11-21T07:45:46.527433Z  INFO http_request{method=GET matched_path="/produce-attr-paths"}: produce_attr_paths: Got request with args: {"flakeRef":"github:ConnorBaker/cuda-packages/8cb28e23b8c7cee612fb68d86a12b263841df109","attrPath":"legacyPackages.x86_64-linux.pkgsCuda.sm_89.cudaPackages_12"}
    # > produceAttrPathsMachine # 100   187    0     0  100   187      0    154  0:00:01  0:00:01 --:--:--   154100   187    0     0  100   187      0     84  0:00:02  0:00:02 --:--:--    84100   187    0     0  100   187      0     58  0:00:03  0:00:03 --:--:--    58100   187    0     0  100   187      0     44  0:00:04  0:00:04 --:--:--    44[   15.891352] produce-attr-paths[669]: 2024-11-21T07:45:50.921160Z ERROR http_request{method=GET matched_path="/produce-attr-paths"}: produce_attr_paths::nix_search: parse_error=Error("EOF while parsing a value", line: 1, column: 0) stderr="warning: error: unable to download 'https://github.com/ConnorBaker/cuda-packages/archive/8cb28e23b8c7cee612fb68d86a12b263841df109.tar.gz': Could not resolve hostname (6); retrying in 311 ms\nwarning: error: unable to download 'https://github.com/ConnorBaker/cuda-packages/archive/8cb28e23b8c7cee612fb68d86a12b263841df109.tar.gz': Could not resolve hostname (6); retrying in 509 ms\nwarning: error: unable to download 'https://github.com/ConnorBaker/cuda-packages/archive/8cb28e23b8c7cee612fb68d86a12b263841df109.tar.gz': Could not resolve hostname (6); retrying in 1096 ms\nwarning: error: unable to download 'https://github.com/ConnorBaker/cuda-packages/archive/8cb28e23b8c7cee612fb68d86a12b263841df109.tar.gz': Could not resolve hostname (6); retrying in 2421 ms\nerror:\n       … while fetching the input 'github:ConnorBaker/cuda-packages/8cb28e23b8c7cee612fb68d86a12b263841df109'\n\n       error: Failed to open archive (Source threw exception: error: unable to download 'https://github.com/ConnorBaker/cuda-packages/archive/8cb28e23b8c7cee612fb68d86a12b263841df109.tar.gz': Could not resolve hostname (6))\n" stdout=""
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
      produceAttrPathsMachine.succeed("query-attr-paths")
    '';
  # clientMachine.systemctl("start network-online.target")
  # clientMachine.wait_for_unit("network-online.target")
  # clientMachine.wait_until_succeeds("curl -L -vvvvv 'http://produceAttrPathsMachine:3000/produce-attr-paths'")
  # clientMachine.wait_for_unit("network-online.target")
  # clientMachine.succeed("which query-attr-paths")
  # clientMachine.succeed("query-attr-paths")
}
